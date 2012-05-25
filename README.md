![Manifesto](https://github.com/heroku/manifesto/raw/master/public/images/manifesto.jpg)

The preamble to the main text of the Manifesto states that the continent of Europe fears the "spectre of communism", and the powers of old Europe are uniting in "a holy alliance [intended to] exorcise this spectre". Marx refers here to not only the houses of power and landed gentry of old Europe--the bourgeoisie--but diverse factions such as the papacy and the emerging corporate world as well.

## Deployment

```
heroku create --stack cedar
heroku addons:add heroku-postgresql:dev
heroku config:add AWS_ACCESS_KEY_ID=...
heroku config:add AWS_SECRET_ACCESS_KEY=...
heroku config:add S3_BUCKET=...
heroku config:add GOOGLE_OAUTH_DOMAIN=...
heroku config:add RACK_COOKIE_SECRET...
git push heroku master
heroku run migrations
heroku ps:scale web=1
```
