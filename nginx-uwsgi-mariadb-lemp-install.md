# LEMP Stack with Nginx, uWSGI, and MariaDB on Ubuntu.

>While Python projects deployed using Nginx and uWSGI can have an overwhelming number configuration options available, deploying basic apps with them can actually be pretty painless. Here's one simple option for setting up your LEMP stack on Ubuntu and deploying a [Flask ](http://flask.pocoo.org/)application.

## Getting Started

Before installing any new software, make sure your system is up to date. If installing MariaDB, you'll first need to [add the right repository for your release](https://downloads.mariadb.org/mariadb/repositories). The below example adds a repository for MariaDB 5.5 on Ubuntu 12.04.

```shell
sudo apt-get install python-software-properties
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
sudo add-apt-repository 'deb http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu precise main'
```

Regardless of whether or not you're installing MariaDB, update your package lists and upgrade any necessary packages.

```shell
sudo apt-get update
sudo apt-get -y upgrade
```

Install pip and some dependent packages.

```shell
sudo apt-get -y install build-essential debconf-utils python-dev libpcre3-dev libssl-dev python-pip
```

## MariaDB

If the appropriate repository was added, begin MariaDB installation. During this installation you'll be asked to set a password for the MariaDB root user.

```shell
apt-get -y install mariadb-server
```

Once the installation finishes, run a script and follow the prompts to secure it.

```shell
mysql_secure_installation
```
## Nginx

The Nginx package installed by the Ubuntu repository will likely be much older than the current release. This should work just fine for your app, but you'll miss out any new features and fixes.

```shell
sudo apt-get -y install nginx
```

If you want the newest version of Nginx, you can add the repository for the latest stable release.

```shell
sudo add-apt-repository ppa:nginx/stable
sudo apt-get update
sudo apt-get -y install nginx
```

Visit your server's hostname or IP address in your browser. If the installation was successful you'll see a placeholder site that can be disabled by removing its link in sites-enabled.

```shell
sudo rm /etc/nginx/sites-enabled/default
```

Create a new site configuration for you application. Here we're using a [Unix socket instead of TCP](http://nginx.org/en/docs/http/ngx_http_upstream_module.html).

```shell
sudo nano /etc/nginx/sites-available/flaskapp
```

```shell
server {
  listen 80;
  server_name $hostname;

  location /static {
    alias /srv/www/flaskapp/app/static;
  }

    location / { try_files $uri @flaskapp; }
    location @flaskapp {
        include uwsgi_params;
        uwsgi_pass unix:/tmp/flaskapp.sock;
    }
}
```

Create directories for your site and link the site's configuration to sites-enabled so Nginx will use it.

```shell
sudo mkdir -p /srv/www/flaskapp/app/static
sudo mkdir -p /srv/www/flaskapp/app/templates
```

```shell
sudo ln -s /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled/flaskapp
```

## uWSGI

Install uWSGI with pip and create directories for configuration files and logs.

```shell
pip install uwsgi
mkdir /etc/uwsgi
mkdir /var/log/uwsgi
```

Emperor mode is great for handling apps because it will spawn, stop, and reload processes as necessary. In this deployment the Emperor is started via Upstart with very basic parameters to allow for more flexibility when configuring applications.

```shell
sudo nano /etc/init/uwsgi-emperor.conf
```

```shell
description "uWSGI Emperor"
start on runlevel [2345]
stop on runlevel [06]
exec uwsgi --die-on-term --emperor /etc/uwsgi --logto /var/log/uwsgi/uwsgi.log
```

Create a uWSGI configuration file for your application.

```shell
sudo nano /etc/uwsgi/flaskapp.ini
```

```shell
[uwsgi]
chdir = /srv/www/flaskapp
logto = /var/log/uwsgi/flaskapp.log
virtualenv = /srv/www/flaskapp/venv
socket = /tmp/flaskapp.sock
uid = www-data
gid = www-data
master = true
wsgi-file = wsgi.py
callable = app
vacuum = true`</pre>
Create a simple application file to test the configuration.
```

```shell
sudo nano /srv/www/flaskapp/wsgi.py
```

```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    return "It works!"
```

## Final Steps

Install Flask within a virtualenv.

```shell
sudo pip install virtualenv
cd /srv/www/flaskapp
virtualenv venv
source venv/bin/activate
pip install flask
```

Change the permissions so www-data can access application files.

```shell
sudo chgrp -R www-data /srv/www/*
sudo chmod -R g+rw /srv/www/*
sudo sh -c 'find /srv/www/* -type d -print0 | sudo xargs -0 chmod g+s'
```

Start uWSGI and restart Nginx.

```shell
start uwsgi-emperor
service nginx restart
```

Visit your server's hostname or IP in your browser once again. You should see, "It works!"
