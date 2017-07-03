require 'net/http'
require 'json'
require 'ostruct'

class DroneClient < Client
  def initialize(token, repository)
    @token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0ZXh0IjoiYW5raXRhZ3VwdGExMiIsInR5cGUiOiJ1c2VyIn0.oyj973oZ36Qamg7uqSpV84Kcfq1xuRxFRYfo_IPVTr8'
    @repository = repository
  end

  def fetch_builds
    uri = URI.parse("#{drone_endpoint}?access_token=#{@token}")
    request = Net::HTTP::Get.new(uri)
    response = fetch_response(uri, request)
    JSON.parse(response.body)
  end

  def cancel_build(build_id)
    endpoint = [drone_endpoint, build_endpoint(build_id)].join('/')
    uri = URI.parse("#{endpoint}?access_token=#{@token}")
    request = Net::HTTP::Delete.new(uri)
    response = fetch_response(uri, request)
    JSON.parse(response.body)
  end

  def commits(response)
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

  private

  def drone_endpoint
    [
      ENV['DRONE_ENDPOINT'],
      'api/repos',
      ENV['OWNER'],
      ENV['REPOSITORY'],
      'builds'
    ].join('/')
  end

  def build_endpoint(build_id)
    "#{build_id}/1"
  end
end
