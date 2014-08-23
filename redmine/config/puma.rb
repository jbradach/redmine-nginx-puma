#!/usr/bin/env puma

# https://gist.github.com/jbradach/6ee5842e5e2543d59adb

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
