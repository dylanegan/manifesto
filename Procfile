web: bundle exec thin -p $PORT -E $RACK_ENV config.ru
console: bundle exec irb -r "./app" -r irb/completion
migrations: bundle exec sequel -m migrations $DATABASE_URL
