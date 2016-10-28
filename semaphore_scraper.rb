require 'open-uri'
require 'json'
require 'pry'

class SemaphoreScraper
  API_URL     = "https://semaphoreci.com/api"
  API_VERSION = "v1"

  def initialize(auth_token)
    @auth_token = auth_token
  end

  def build_stats(hash_id, branch_id, build_number)
    JSON.parse(open(build_stats_url(hash_id, branch_id, build_number)).read)
  end

  def build_log(hash_id, branch_id, build_number)
    JSON.parse(open(build_log_url(hash_id, branch_id, build_number)).read)
  end

  private

  def auth_token_param
    "?auth_token=#{@auth_token}"
  end

  def base_url
    "#{API_URL}/#{API_VERSION}"
  end

  def build_url(hash_id, branch_id, build_number)
    "#{base_url}/projects/#{hash_id}/#{branch_id}/builds/#{build_number}"
  end

  def build_stats_url(hash_id, branch_id, build_number)
    "#{build_url(hash_id, branch_id, build_number)}/#{auth_token_param}"
  end

  def build_log_url(hash_id, branch_id, build_number)
    "#{build_url(hash_id, branch_id, build_number)}/log#{auth_token_param}"
  end
end
