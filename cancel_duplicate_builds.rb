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
  logger.info "Whee Canceling Build ##{build_id}"
  uri = URI.parse("https://api.travis-ci.com/builds/#{build_id}/cancel")
  request = Net::HTTP::Post.new(uri)
  request['Accept'] = 'application/vnd.travis-ci.2+json'
  request['Authorization'] = "token #{token}"
  response = JSON.parse(fetch_response(uri, request).body)
  logger.info response
  response
end

def fetch_response(uri, request)
  Net::HTTP.start(
    uri.hostname, uri.port, use_ssl: uri.scheme == 'https'
  ) do |http|
    http.request(request)
  end
rescue e
  logger.info "Error: #{e}"
end

def fetch_all_builds(token, repository)
  logger.info 'Fetching Builds'
  fetch_builds(repository, token)
end

def map_duplicate_builds(json_response)
  commits = json_response['commits']
  duplicate_hash = OpenStruct.new(seen: {}, duplicates: {})
  commit_hash =
    if commits
      logger.info 'Finding duplicate builds'
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
      logger.info "No commits in json response #{json_response}"
      duplicate_hash
    end

  commit_hash.duplicates.values.flatten
end

def cancel_duplicate_builds(json_response, duplicate_commits, token)
  logger.info 'Canceling Builds'

  builds = json_response['builds']
  grouped_builds = builds.group_by { |build| build['commit_id'] } if builds
  duplicate_commits.reduce([]) do |canceled_builds, commit_id|
    build = grouped_builds[commit_id].first
    if %w(passed canceled failed errored).include?(build['state'])
      next canceled_builds
    end
    response = cancel_build(token, build['id'])
    canceled_builds << { build['id'] => response }
    canceled_builds
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
  canceled_builds =
    cancel_duplicate_builds(json_response, duplicate_commits, token)
  { canceled_builds: canceled_builds }
end
