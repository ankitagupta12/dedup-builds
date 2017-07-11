require 'sinatra'

class DuplicateBuilds < Sinatra::Base
  set :bind, '0.0.0.0'

  get '/' do
    'I\'m alive!'
  end

  def cancel_builds(client)
    json_response = client.fetch_all_builds
    duplicate_commits = client.map_duplicate_builds(
      client.commits(json_response),
      client.pull_request_key
    )
    return if duplicate_commits.empty?
    canceled_builds =
      client.cancel_duplicate_builds(
        client.builds(json_response),
        duplicate_commits,
        client.ignored_build_statuses,
        client.build_key,
        client.commit_id
      )
    { canceled_builds: canceled_builds }
  end

  post '/cancel-travis-builds' do
    travis_client = TravisClient.new(ENV['TRAVIS_TOKEN'], ENV['REPOSITORY'])
    result = cancel_builds(travis_client)
    "Builds cancelled! #{result}"
  end

  post '/cancel-drone-builds' do
    drone_client = DroneClient.new(ENV['DRONE_TOKEN'], ENV['REPOSITORY'])
    result = cancel_builds(drone_client)
    "Builds cancelled! #{result}"
  end
end
