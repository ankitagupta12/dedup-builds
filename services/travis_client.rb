class TravisClient < Client
  def initialize(token, repository)
    @token = token
    @repository = repository
  end

  def fetch_builds
    uri = URI.parse(
      "https://api.travis-ci.com/repos/#{ENV['ORGANISATION']}/#{@repository}/builds?limit=30"
    )
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/vnd.travis-ci.2+json'
    request['Authorization'] = "token #{@token}"
    response = fetch_response(uri, request)
    JSON.parse(response.body)
  end

  def cancel_build(build_id)
    logger.info "Whee Canceling Build ##{build_id}"
    uri = URI.parse("https://api.travis-ci.com/builds/#{build_id}/cancel")
    request = Net::HTTP::Post.new(uri)
    request['Accept'] = 'application/vnd.travis-ci.2+json'
    request['Authorization'] = "token #{@token}"
    response = fetch_response(uri, request).body
    logger.info response
    response
  end

  def commits(response)
    response['commits']
  end

  def builds(response)
    response['builds']
  end

  def pull_request_key
    'pull_request_number'
  end

  def ignored_build_statuses
    %w(passed canceled failed errored)
  end

  def build_key
    'id'
  end

  def commit_id
    'commit_id'
  end
end
