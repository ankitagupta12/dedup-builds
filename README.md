# dedup builds

Cancel duplicate builds in travis or drone

* Builds corresponding to the same pull request can be cancelled using these endpoints
* If you want your build to run anyway, end the commit message with `--dup`
 * Example. `git commit -m "Change file name --dup"`
* Obtain your travis access token by doing: `gem install travis && travis login && travis token --pro`
* Get the repository name from travis.
* Get drone token from your account settings.


Environment vars to set up :
 * `TRAVIS_TOKEN`
 * `ORGANISATION`
 * `REPOSITORY`
 * `DRONE_ENDPOINT`
 * `DRONE_TOKEN`

* Once the sinatra application has been deployed to a server, it can be accessed publicly, setup a webhook in your github repository pointing to `'/cancel-drone-builds'` or `'/cancel-travis-builds'`. Start your server locally by :
 * `bundle exec rackup -p 3000`
