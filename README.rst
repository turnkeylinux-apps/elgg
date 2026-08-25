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
   
   - Elgg 7.0.5 is installed from the official complete release archive to
     /var/www/elgg. The upstream-published SHA-256 digest is verified during
     the build.

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
- If you have any problems please contact TurnKey support:
  - paying users can contact TurnKey support via the `TurnKey Hub`_ or
    support@turnkeylinux.org
  - free users can access community support via the `TurnKey forums`_

To update, first create a TKLBAM or equivalent backup of the database, data
directory and application files. Review the release notes and the official
`Elgg upgrade documentation`_, then select the compatible Elgg 7 release:

    cd /var/www/elgg
    turnkey-composer --with-all-dependencies require elgg/elgg:~7.0.5
    turnkey-elgg-cli upgrade async -v

Adjust the version constraint only after reviewing its PHP requirements and
upgrade notes.

.. _Elgg: https://www.elgg.org/
.. _TurnKey Core: https://www.turnkeylinux.org/core
.. _Adminer: https://www.adminer.org/
.. _TurnKey Hub: https://hub.turnkeylinux.org/
.. _TurnKey forums: https://www.turnkeylinux.org/forum/
.. _Elgg upgrade documentation: https://learn.elgg.org/en/stable/admin/upgrading.html
