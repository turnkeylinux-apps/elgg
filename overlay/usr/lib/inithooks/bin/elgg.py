#!/usr/bin/python
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
import inithooks_cache

import bcrypt

from dialog_wrapper import Dialog
from mysqlconf import MySQL

def usage(s=None):
    if s:
        print >> sys.stderr, "Error:", s
    print >> sys.stderr, "Syntax: %s [options]" % sys.argv[0]
    print >> sys.stderr, __doc__
    sys.exit(1)

DEFAULT_DOMAIN="www.example.com"

def main():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h",
                                       ['help', 'pass=', 'email=', 'domain='])
    except getopt.GetoptError, e:
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

    inithooks_cache.write('APP_DOMAIN', domain)

    salt = bcrypt.gensalt(10) 
    hashpass = bcrypt.hashpw(password, salt)

    m = MySQL()
    m.execute('UPDATE elgg.elgg_users_entity SET password_hash=\"%s\" WHERE username=\"admin\";' % hashpass)

    m.execute('UPDATE elgg.elgg_users_entity SET email=\"%s\" WHERE username=\"admin\";' % email)

    m.execute('UPDATE elgg.elgg_metastrings SET string=\"%s\" WHERE string LIKE \"%%@%%\";' % email)
    m.execute('UPDATE elgg.elgg_sites_entity SET url=\"%s\" WHERE guid = 1;' % domain)

    with open('/etc/cron.d/elgg', 'r') as fob:
        contents = fob.read()

    contents = re.sub("ELGG='.*'", "ELGG='%s'" % domain, contents)

    with open('/etc/cron.d/elgg', 'w') as fob:
        fob.write(contents)

    apache_conf = "/etc/apache2/sites-available/elgg.conf"
    system("sed -i \"\|RewriteRule|s|https://.*|https://%s/\$1 [R,L]|\" %s" % (domain, apache_conf))

    system("service apache2 restart")

if __name__ == "__main__":
    main()
