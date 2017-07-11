class DroneClient < Client
  def initialize(token, repository)
    @token = token
    @repository = repository
  end

  def fetch_builds
    uri = URI.parse("#{drone_endpoint}?access_token=#{@token}")
    request = Net::HTTP::Get.new(uri)
    response = fetch_response(uri, request)
    JSON.parse(response.body)
  end

  def cancel_build(build_id)
    logger.info "Cancelling build with id: #{build_id}"
    endpoint = [drone_endpoint, build_endpoint(build_id)].join('/')
    uri = URI.parse("#{endpoint}?access_token=#{@token}")
    request = Net::HTTP::Delete.new(uri)
    fetch_response(uri, request).body
  end

  def commits(response)
    response
  end

  def builds(response)
    response
  end

  def pull_request_key
    'branch'
  end

  def ignored_build_statuses
    %w(success failure)
  end

  def build_key
    'number'
  end

  def commit_id
    'id'
  end

  private

  def drone_endpoint
    [
      ENV['DRONE_ENDPOINT'],
      'api/repos',
      ENV['ORGANIZATION'],
      ENV['REPOSITORY'],
      'builds'
    ].join('/')
  end

  def build_endpoint(build_id)
    "#{build_id}/1"
  end
end
