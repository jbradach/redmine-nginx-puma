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

# https://gist.github.com/jbradach/17e73fa6ddc365bb0242

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
