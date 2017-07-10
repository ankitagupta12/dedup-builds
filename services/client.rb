require 'net/http'
require 'json'
require 'ostruct'
require 'logger'

class Client
  def cancel_duplicate_builds(builds, duplicate_commits, ignored_build_statuses, build_key, commit_id)
    logger.info 'Canceling Builds'
    grouped_builds = builds.group_by { |build| build[commit_id] } if builds
    duplicate_commits.map do |commit_id|
      build = grouped_builds[commit_id].last
      next if ignored_build_statuses.include?(build['state'] || build['status'])
      build_reference = build[build_key]
      response = cancel_build(build_reference)
      { build_reference => response }
    end.compact
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

  def fetch_all_builds
    logger.info 'Fetching Builds'
    fetch_builds
  end

  def duplicate_enabled_commit?(commit_message)
    commit_message.match(/--dup$/)
  end

  def map_duplicate_builds(commits, pull_request_key)
    duplicate_hash = OpenStruct.new(seen: {}, duplicates: {})
    commit_hash =
      if commits
        logger.info 'Finding duplicate builds'
        commits.reduce(duplicate_hash) do |commit_struct, commit|
          pull_request = commit[pull_request_key]
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

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
