redmine-nginx-puma
=========

Sample configuration files and documentation for installing Redmine with Nginx and Puma.

  - Redmine 2.5.2.stable
  - Nginx 1.6.0
  - Puma 2.9.0
  - MariaDB 10.0.13
  - Ubuntu 14.04


> This installation method attempts to install and run programs as a dedicated local user whenever possible to avoid system-wide clutter.

Documentation
----
* [redmine-nginx-puma-install.md](https://github.com/jbradach/redmine-nginx-puma/blob/master/redmine-nginx-puma-install.md)
* [nginx-uwsgi-mariadb-lemp-install.md](https://github.com/jbradach/redmine-nginx-puma/blob/master/nginx-uwsgi-mariadb-lemp-install.md)
* [redmine-smtp-sendmail-configuration.md](https://github.com/jbradach/redmine-nginx-puma/blob/master/redmine-smtp-sendmail-configuration.md)
* [redmine-forwarding-incoming-email.md](https://github.com/jbradach/redmine-nginx-puma/blob/master/redmine-forwarding-incoming-email.md)

Configuration
----
The directories in this project correspond to Ubuntu server locations and contain sample configuration files that can be used there.

| Local Directory | Server Path           | Comments                        |
|-----------------|-----------------------|---------------------------------|
| mail            | /etc/mail             | Sendmail configuration files    |
| home            | /home/redmine         | Redmine user home directory     |
| init.d          | /etc/init.d           | Start/stop scripts for services |
| nginx           | /etc/nginx            | Nginx configuration files       |
| redmine         | /home/redmine/redmine | Redmine application directory   |

Meta
----
* Author: James Bradach
* Twitter: [@toomuchtofu](http://twitter.com/toomuchtofu)
* Site: http://blog.rudeotter.com

License
----
This project is licensed under the [MIT License](http://opensource.org/licenses/mit-license.php).
