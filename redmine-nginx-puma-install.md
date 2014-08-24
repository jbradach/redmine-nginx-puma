# Install Redmine using Nginx and Puma on Ubuntu 14.04.

> This guide was inspired by a [blog post I wrote](http://blog.rudeotter.com/2014/08/install-redmine-with-nginx-puma-and.html) and outlines the steps I took to install Redmine 2.5.2 using Nginx, Puma, and MariaDB on a server running Ubuntu 14.04. However, I will not be covering how to install Nginx or MariaDB here. If you're looking for more information on setting up Nginx and MariaDB, check out an earlier tutorial I write on [deploying a LEMP stack](http://blog.rudeotter.com/2014/01/setup-nginx-uwsgi-mariadb-ubuntu.html).

## Package Updates and Dependencies

Update your package lists and upgrade any existing packages.

```shell
sudo apt-get update
sudo apt-get -y upgrade
```

Install a few dependencies to make sure we can compile Ruby and use the necessary gems.

```shell
sudo apt-get install autoconf git-core subversion curl \
    libmagickwand-dev bison build-essential libmariadbclient-dev libssl-dev \
    libreadline-dev libyaml-dev zlib1g-dev python-software-properties
```

## Redmine Local User

Create a new user for Redmine. We'll be installing Ruby and Redmine into that user's home directory so go ahead and switch to that user.

```shell
sudo adduser --disabled-login --gecos 'Redmine' redmine
sudo su - redmine
```

## Install Ruby Environment

I used [rbenv ](https://github.com/sstephenson/rbenv)and the plugin [ruby-build](https://github.com/sstephenson/ruby-build) to manage my Ruby installation and gems. They're can be cloned from GitHub.

```shell
git clone git://github.com/sstephenson/rbenv.git .rbenv
git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
```

Add rbenv to your shell's path. Restart your shell to enable access to the command.

```shell
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
exec $SHELL -l
```

Now install Ruby. This will take a while so be patient.

```shell
rbenv install 2.1.2
```

Once installed, set it as the global Ruby version and test the command. You should see something like **ruby 2.1.2p95 (2014-05-08 revision 45877) [x86_64-linux]**.

```shell
rbenv global 2.1.2
ruby -v
```

## Download and Configure Redmine
Checkout the source for Redmine, add some directories, and adjust the permissions.

```shell
svn co http://svn.redmine.org/redmine/branches/2.5-stable redmine
cd redmine
mkdir -p tmp/pids tmp/sockets public/plugin_assets
chmod -R 755 files log tmp public/plugin_assets
```

Create the Puma configuration file.

```shell
nano config/puma.rb
```

```shell
#!/usr/bin/env puma

# start puma with:
# RAILS_ENV=production bundle exec puma -C ./config/puma.rb

application_path = '/home/redmine/redmine'
directory application_path
environment 'production'
daemonize true
pidfile "#{application_path}/tmp/pids/puma.pid"
state_path "#{application_path}/tmp/pids/puma.state"
stdout_redirect "#{application_path}/log/puma.stdout.log", "#{application_path}/log/puma.stderr.log"
bind "unix://#{application_path}/tmp/sockets/redmine.sock"
```

You can also grab the [Puma configuration from GitHub](https://gist.github.com/jbradach/6ee5842e5e2543d59adb).

```shell
curl -Lo /home/redmine/redmine/config/puma.rb \
    https://gist.githubusercontent.com/jbradach/6ee5842e5e2543d59adb/raw/
```

## Configure MariaDB/MySQL

Connect to MariaDB/MySQL to create a Redmine database and user.

```shell
mysql -u root -p
```

```shell
CREATE DATABASE redmine CHARACTER SET utf8;
CREATE USER 'redmine'@'localhost' IDENTIFIED BY 'YOURPASSWORD';
GRANT ALL PRIVILEGES ON redmine.* TO 'redmine'@'localhost';
\q
```

Copy the database configuration example and update the production server with the new credentials.

```shell
cp config/database.yml.example config/database.yml
nano config/database.yml
```

```shell
...
production:
  adapter: mysql2
  database: redmine
  host: localhost
  username: redmine
  password: "YOURPASSWORD"
  encoding: utf8
...
```

## Install Gems

```shell
echo "gem: --no-ri --no-rdoc" >> ~/.gemrc
echo -e "# Gemfile.local\ngem 'puma'" >> Gemfile.local
gem install bundler
rbenv rehash
bundle install --without development test
```

## Generate Token and Prepare Database

Generate random key for encoding cookies, create database structure, and insert default configuration data.

```shell
rake generate_secret_token
RAILS_ENV=production rake db:migrate
RAILS_ENV=production rake redmine:load_default_data
```

## Test Installation

Run a test with WEBrick to make sure Redmine is working. Open the URL http://SERVERNAME:3000 in your browser and confirm that Redmine loads successfully.

```shell
ruby script/rails server webrick -e production
```

If you need to change the default port, just append -p followed by desired port number.

```shell
ruby script/rails server webrick -e production -p5000
```

At this point, you're done issuing commands as your local Redmine user. Go back to your own user account by typing **exit**.

## Init Configuration

If the tests were successful, add an init script to start Redmine automatically and allow you to manage the process using **service**. Be sure you've exited your Redmine user, as the rest of the steps require root access.

```shell
sudo nano /etc/init.d/redmine
```

```shell
#! /bin/sh
### BEGIN INIT INFO
# Provides:          redmine
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts redmine with puma
# Description:       Starts redmine from /home/redmine/redmine.
### END INIT INFO

# Do NOT "set -e"

APP_USER=redmine
APP_NAME=redmine
APP_ROOT="/home/$APP_USER/$APP_NAME"
RAILS_ENV=production

RBENV_ROOT="/home/$APP_USER/.rbenv"
PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"
SET_PATH="cd $APP_ROOT; rbenv rehash"
DAEMON="bundle exec puma"
DAEMON_ARGS="-C $APP_ROOT/config/puma.rb -e $RAILS_ENV"
CMD="$SET_PATH; $DAEMON $DAEMON_ARGS"
NAME=redmine
DESC="Redmine Service"
PIDFILE="$APP_ROOT/tmp/pids/puma.pid"
SCRIPTNAME="/etc/init.d/$NAME"

cd $APP_ROOT || exit 1

sig () {
        test -s "$PIDFILE" && kill -$1 `cat $PIDFILE`
}

case $1 in
  start)
        sig 0 && echo >&2 "Already running" && exit 0
        su - $APP_USER -c "$CMD"
        ;;
  stop)
        sig QUIT && exit 0
        echo >&2 "Not running"
        ;;
  restart|reload)
        sig USR2 && echo "Restarting" && exit 0
        echo >&2 "Couldn't restart"
        ;;
  status)
        sig 0 && echo >&2 "Running " && exit 0
        echo >&2 "Not running" && exit 1
        ;;
  *)
        echo "Usage: $SCRIPTNAME {start|stop|restart|status}" >&2
        exit 1
        ;;
esac

:
```

You can also grab the [Redmine/Puma init script from GitHub](https://gist.github.com/jbradach/17e73fa6ddc365bb0242).

```shell
sudo curl -Lo /etc/init.d/redmine \
    https://gist.githubusercontent.com/jbradach/17e73fa6ddc365bb0242/raw/
```

```shell
chmod +x /etc/init.d/redmine
sudo update-rc.d redmine defaults
```

## Nginx Server Block

Finally, just set up the Nginx server block with a Redmine/Puma upstream and the appropriate proxy settings.

```shell
sudo nano /etc/nginx/sites-available/redmine
```

```nginx
upstream puma_redmine {
  server unix:/home/redmine/redmine/tmp/sockets/redmine.sock fail_timeout=0;
  #server 127.0.0.1:3000;
}

server {
  server_name YOUR.SERVER.NAME;
  listen 80;
  root /home/redmine/redmine/public;

  location / {
    try_files $uri/index.html $uri.html $uri @ruby;
  }

  location @ruby {
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP  $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_redirect off;
    proxy_read_timeout 300;
    proxy_pass http://puma_redmine;
  }
}
```

Yes, the [Nginx configuration is on GitHub](https://gist.github.com/jbradach/31ad6d9c84c3be3b5730), too.

```shell
sudo curl -Lo /etc/nginx/sites-available/redmine \
    https://gist.githubusercontent.com/jbradach/31ad6d9c84c3be3b5730/raw/
```

Link the config to sites-enabled and restart Nginx and you're done!

```shell
sudo ln -s /etc/nginx/sites-available/redmine /etc/nginx/sites-enabled/redmine
sudo service nginx restrart
```

Log into Redmine with the default account admin/admin. Visit My Account to change the default password. You can change the default account's username by visiting the Users section under Administration.
