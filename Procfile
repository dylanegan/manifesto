web: bundle exec thin -p $PORT -e $RACK_ENV -R config.ru start
api: bundle exec thin -p $PORT -e $RACK_ENV -R config.api.ru start
app: bundle exec thin -p $PORT -e $RACK_ENV -R config.application.ru start
console: bundle exec irb -I lib -r manifesto/application -r irb/completion
migrations: bundle exec sequel -m migrations $DATABASE_URL
bytea_output_fix: bundle exec migrations/optional/bytea
