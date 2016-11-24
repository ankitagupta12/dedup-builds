# dtrav

Cancel duplicate builds in travis

* Builds corresponding to the same pull request can be cancelled using this script
* If you want your build to run anyway, end the commit message with `--dup`
 * Example. `git commit -m "Change file name --dup"`
* Obtain your travis access token by doing: `gem install travis && travis login && travis token --pro`
* Get the repository name from travis. By default, the repository name is set to `HB-Backend`
* Run the script
 * Example `./cancel_duplicate_builds.rb 'token_name repository_name'`

Environment vars to set up : 
 * `TRAVIS_TOKEN` 
 * `ORGANISATION`
 * `REPOSITORY`

You then need to setup a webhook in your github repository.
