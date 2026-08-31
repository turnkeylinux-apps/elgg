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

To update, first create a TKLBAM or equivalent backup of the database,
``/var/www/elgg-data`` and application files. Review the release notes and the
official `Elgg upgrade documentation`_, then select a compatible Elgg 7
complete release. Record its asset URL and published SHA-256 digest from the
official release before downloading it. For example, after setting ``version``
and ``sha256`` to those reviewed values:

    version=7.0.5
    sha256=a369a5b97c22e31998d7ed3e107c410efbcd1d8f3a3edacea4b64af8a3027c10
    archive=/tmp/elgg-$version.zip
    staging=/var/www/elgg-$version
    curl --fail --location \
        https://github.com/Elgg/Elgg/releases/download/$version/elgg-$version.zip \
        --output $archive
    printf '%s  %s\n' "$sha256" "$archive" | sha256sum --check -
    unzip -q $archive -d /tmp/elgg-release
    mv /tmp/elgg-release/elgg-$version $staging
    cp -a /var/www/elgg/elgg-config/settings.php \
        $staging/elgg-config/settings.php

Copy each site-specific plugin and reapply any recorded application
customizations to ``$staging`` before the replacement. The database and
``/var/www/elgg-data`` remain in place. Then replace the application tree and
run Elgg's database upgrade:

    systemctl stop apache2
    mv /var/www/elgg /var/www/elgg.previous
    mv $staging /var/www/elgg
    chown -R root:root /var/www/elgg
    chown -R www-data:www-data /var/www/elgg-data
    chmod 644 /var/www/elgg/elgg-config/settings.php
    systemctl start apache2
    turnkey-elgg-cli upgrade async -v

Keep ``/var/www/elgg.previous`` until the site has been checked. The complete
release is the application package, so it must be replaced as a unit rather
than updated by requiring ``elgg/elgg`` from its own Composer project.

.. _Elgg: https://www.elgg.org/
.. _TurnKey Core: https://www.turnkeylinux.org/core
.. _Adminer: https://www.adminer.org/
.. _TurnKey Hub: https://hub.turnkeylinux.org/
.. _TurnKey forums: https://www.turnkeylinux.org/forum/
.. _Elgg upgrade documentation: https://learn.elgg.org/en/stable/admin/upgrading.html
