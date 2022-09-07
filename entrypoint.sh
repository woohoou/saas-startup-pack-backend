#!/bin/sh
set -e
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

rm -rf public/packs

exec "$@"