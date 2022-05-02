#!/usr/bin/python3
"""Set Elgg admin password, email and domain to serve

Option:
    --pass=     unless provided, will ask interactively
    --email=    unless provided, will ask interactively
    --domain=   unless provided, will ask interactively
                DEFAULT=www.example.com
"""

import re
import sys
import getopt
from libinithooks import inithooks_cache

import bcrypt

from libinithooks.dialog_wrapper import Dialog
from mysqlconf import MySQL
import subprocess

def usage(s=None):
    if s:
        print("Error:", s, file=sys.stderr)
    print("Syntax: %s [options]" % sys.argv[0], file=sys.stderr)
    print(__doc__, file=sys.stderr)
    sys.exit(1)

DEFAULT_DOMAIN="www.example.com"

def main():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h",
                                       ['help', 'pass=', 'email=', 'domain='])
    except getopt.GetoptError as e:
        usage(e)

    email = ""
    domain = ""
    password = ""
    for opt, val in opts:
        if opt in ('-h', '--help'):
            usage()
        elif opt == '--pass':
            password = val
        elif opt == '--email':
            email = val
        elif opt == '--domain':
            domain = val

    if not password:
        d = Dialog('TurnKey Linux - First boot configuration')
        password = d.get_password(
            "Elgg Password",
            "Enter new password for the Elgg 'admin' account.")

    if not email:
        if 'd' not in locals():
            d = Dialog('TurnKey Linux - First boot configuration')

        email = d.get_email(
            "Elgg Email",
            "Enter email address for the Elgg 'admin' account.",
            "admin@example.com")

    inithooks_cache.write('APP_EMAIL', email)

    if not domain:
        if 'd' not in locals():
            d = Dialog('TurnKey Linux - First boot configuration')

        domain = d.get_input(
            "Elgg Domain",
            "Enter the domain to serve Elgg. Note: Elgg does not support http without further configuration, domain will default to https.",
            DEFAULT_DOMAIN)

    if domain == "DEFAULT":
        domain = DEFAULT_DOMAIN

    fqdn = re.compile(r"https?://")
    fqdn = fqdn.sub('', domain).strip('/')
    domain = ("https://%s/" % fqdn)

    inithooks_cache.write('APP_DOMAIN', fqdn)

    salt = bcrypt.gensalt(10) 
    hashpass = bcrypt.hashpw(password.encode('utf8'), salt)

    m = MySQL()

    try:
        with m.connection.cursor() as cursor:
            cursor.execute('SELECT guid FROM elgg.elgg_entities WHERE type="user" AND owner_guid="0"')
            admin_guid = cursor.fetchone()['guid']
            cursor.execute('SELECT name FROM elgg.elgg_metadata WHERE entity_guid=%s', (admin_guid,))
            assert(cursor.fetchone()['name'])
            # sanity check, if this fails, look at the database. You'll probably need to update
            # all of this database stuff
            cursor.execute(
                'UPDATE elgg.elgg_metadata SET value=%s WHERE entity_guid=%s AND name="password_hash"',
                (hashpass, admin_guid,))
            cursor.execute(
                'UPDATE elgg.elgg_metadata SET value=%s WHERE entity_guid=%s AND name="email"',
                (email, admin_guid,))
            cursor.execute(
                'UPDATE elgg.elgg_metadata SET value=%s WHERE entity_guid=1 AND name="email"',
                (email,))
            m.connection.commit()
    finally:
        m.connection.close()

    with open('/etc/cron.d/elgg', 'r') as fob:
        contents = fob.read()

    contents = re.sub("ELGG='.*'", "ELGG='%s'" % domain, contents)

    with open('/etc/cron.d/elgg', 'w') as fob:
        fob.write(contents)

    elgg_conf = "/var/www/elgg/elgg-config/settings.php"
    subprocess.run(["sed", "-i", '\|^\$CONFIG->wwwroot|s|=.*|= "%s";|' % domain.strip('/'), elgg_conf])

    apache_conf = "/etc/apache2/sites-available/elgg.conf"
    subprocess.run(["sed", "-i", "\|RewriteRule|s|https://.*|https://%s/\$1 [R,L]|" % fqdn, apache_conf])
    subprocess.run(["sed", "-i", "\|RewriteCond|s|!^.*|!^%s$|" % fqdn, apache_conf])
    subprocess.run(["service", "apache2", "restart"])

if __name__ == "__main__":
    main()
