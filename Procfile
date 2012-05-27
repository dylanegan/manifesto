web: bundle exec thin -p $PORT -e $RACK_ENV -R config.application.ru start
api: bundle exec thin -p $PORT -e $RACK_ENV -R config.api.ru start
console: bundle exec irb -r "./app" -r irb/completion
migrations: bundle exec sequel -m migrations $DATABASE_URL
