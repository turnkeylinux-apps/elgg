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
- `PHPMyAdmin`_ administration frontend for MySQL (listening on port
  12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL, phpMyAdmin: username **root**
-  Elgg: username **admin**


.. _Elgg: http://www.elgg.org/
.. _TurnKey Core: http://www.turnkeylinux.org/core
.. _PHPMyAdmin: http://www.phpmyadmin.net
