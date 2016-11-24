require 'net/http'
require 'json'
require 'ostruct'
require 'sinatra'

set :bind, '0.0.0.0'

def duplicate_enabled_commit?(commit_message)
  commit_message.match(/--dup$/)
end

def fetch_builds(repository, token)
  uri = URI.parse(
    "https://api.travis-ci.com/repos/#{ENV['ORGANISATION']}/#{repository}/builds?limit=30"
  )
  request = Net::HTTP::Get.new(uri)
  request['Accept'] = 'application/vnd.travis-ci.2+json'
  request['Authorization'] = "token #{token}"
  response = fetch_response(uri, request)
  JSON.parse(response.body)
end

def cancel_build(token, build_id)
  puts "Whee Canceling Build ##{build_id}"
  uri = URI.parse("https://api.travis-ci.com/builds/#{build_id}/cancel")
  request = Net::HTTP::Post.new(uri)
  request['Accept'] = 'application/vnd.travis-ci.2+json'
  request['Authorization'] = "token #{token}"
  response = fetch_response(uri, request)
  puts response.body
end

def fetch_response(uri, request)
  Net::HTTP.start(
    uri.hostname, uri.port, use_ssl: uri.scheme == 'https'
  ) do |http|
    http.request(request)
  end
rescue e
  puts "Error: #{e}"
end

def fetch_all_builds(token, repository)
  puts 'Fetching Builds'
  json_response = fetch_builds(repository, token)
end

def map_duplicate_builds(json_response)
  commits = json_response['commits']
  duplicate_hash = OpenStruct.new(seen: {}, duplicates: {})
  commit_hash =
    if commits
      puts 'Finding duplicate builds'
      commits.reduce(duplicate_hash) do |commit_struct, commit|
        pull_request = commit['pull_request_number']
        commit_id = commit['id']
        if pull_request &&
           commit_struct.seen.key?(pull_request) &&
           !duplicate_enabled_commit?(commit['message'])
          commit_struct.duplicates[pull_request] ||= []
          commit_struct.duplicates[pull_request] << commit_id
        else
          commit_struct.seen[pull_request] = commit_id
        end
        commit_struct
      end
    else
      puts "No commits in json response #{json_response}"
      duplicate_hash
    end

  duplicate_commits = commit_hash.duplicates.values.flatten
end

def cancel_duplicate_builds(json_response, duplicate_commits, token)
  puts 'Canceling Builds'

  builds = json_response['builds']
  grouped_builds = builds.group_by { |build| build['commit_id'] } if builds
  duplicate_commits.each do |commit_id|
    build = grouped_builds[commit_id].first
    next if %w(passed canceled failed errored).include?(build['state'])
    cancel_build(token, build['id'])
  end
end

get '/' do 
  'I\'m alive!'
end

post '/cancel-builds' do
  token = ENV['TRAVIS_TOKEN']
  repository = ENV['REPOSITORY']

  json_response = fetch_all_builds(token, repository)
  duplicate_commits = map_duplicate_builds(json_response)
  cancel_duplicate_builds(json_response, duplicate_commits, token)
  'Builds canceled'
end
