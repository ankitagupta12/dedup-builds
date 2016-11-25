# dtrav

Cancel duplicate builds in travis

* Builds corresponding to the same pull request can be cancelled using this script
* If you want your build to run anyway, end the commit message with `--dup`
 * Example. `git commit -m "Change file name --dup"`
* Obtain your travis access token by doing: `gem install travis && travis login && travis token --pro`
* Get the repository name from travis.


Environment vars to set up :
 * `TRAVIS_TOKEN`
 * `ORGANISATION`
 * `REPOSITORY`

* Once the sinatra application has been deployed to a server and can be accessed publicly, setup a webhook in your github repository pointing to `'/cancel-builds'`.
