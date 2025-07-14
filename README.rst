Elgg - Social networking engine
===============================

`Elgg`_ is an award-winning social networking engine, delivering the
building blocks that enable businesses, schools, universities and
associations to create their own fully-featured social networks and
applications. It offers blogging, microblogging, file sharing,
networking, groups and a number of other features.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- Elgg configurations:
   
   - Installed from upstream source code to /var/www/elgg

- SSL support out of the box.
- `Adminer`_ administration frontend for MySQL (listening on port
   12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL: username **root**
-  Adminer: username **adminer**
-  Elgg: username **admin**


Updating Elgg
-------------

Notes:
- Elgg will not be automatically updated and must be updated manually as per
  the instructions below.
- AWS Marketplace users will need to prefix most commands with 'sudo'.
- when running the 'composer' commands you will see a warning regarding
  running as 'root'. Hit enter to accept. Running as root is required because
  as a security measure, Elgg is "locked down" and only writeable by root.
- If you have any problems please contact TurnKey support:
  - paying users can contact TurnKey support via the `TurnKey Hub`_ or
    support@turnkeylinux.org
  - free users can access community support via the `TurnKey forums`_

Steps to update:
1. create backup of your Elgg site - using TKLBAM or some other method.
2. log into a terminal of your server as the 'root' user ('admin' on AWS
   Marketplace server)
3. The commands below will need to be adjusted depending on which TurnKey
   Elgg appliance you are running. These explictly apply to v18.x and
   demonstrate upgrading Elgg to v6.2.3 on:

    cd /var/www/elgg
    # this is only required the first time you update
    sed -En '/"php"/ s|(.*)8.0(.*)|\18.2\2|p' composer.json
    composer --with-all-dependencies -vv require elgg/elgg:~6.2.3
    # adjust the above Elgg version to upgrade to newer version.
    composer update -vv
    ./vendor/bin/elgg-cli upgrade async -v

.. _Elgg: https://www.elgg.org/
.. _TurnKey Core: https://www.turnkeylinux.org/core
.. _Adminer: https://www.adminer.org/
.. _TurnKey Hub: https://hub.turnkeylinux.org/
.. _TurnKey forums: https://www.turnkeylinux.org/forum/
