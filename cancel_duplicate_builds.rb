require 'sinatra'

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
  canceled_builds =
    client.cancel_duplicate_builds(
      json_response['builds'],
      duplicate_commits,
      client.ignored_build_statuses,
      client.build_key
    )
  { canceled_builds: canceled_builds }
end

post '/cancel-travis-builds' do
  travis_client = TravisClient.new(ENV['TRAVIS_TOKEN'], ENV['REPOSITORY'])
  cancel_builds(travis_client)
end

post '/cancel-drone-builds' do
  drone_client = DroneClient.new(ENV['DRONE_TOKEN'], ENV['REPOSITORY'])
  cancel_builds(drone_client)
end
