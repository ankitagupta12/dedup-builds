$: << File.dirname(__FILE__)
require 'duplicate_builds'
run DuplicateBuilds.new

require 'dotenv'
Dotenv.load

require 'pry'
require 'services/client'
require 'services/drone_client'
require 'services/travis_client'
