require "http/client"
require "json"
require "./app"

class API
  API_ROOT = "https://api.trello.com/1/"

  def self.get(path : String, params : String)
    url = "#{API_ROOT}/#{path}?#{App::CREDENTIALS}&#{params}"
    App::LOG.debug("GETting URL: #{url}")
    response = HTTP::Client.get(url)
    json = JSON.parse(response.body)
    json
  end

  def self.post(path : String, params : String)
    url = "#{API_ROOT}/#{path}?#{App::CREDENTIALS}&#{params}"
    App::LOG.debug("POSTing URL: #{url}")
    response = HTTP::Client.post(url)
  end

  def self.put(path : String, params : String)
    url = "#{API_ROOT}/#{path}?#{App::CREDENTIALS}&#{params}"
    App::LOG.debug("PUTting URL: #{url}")
    response = HTTP::Client.put(url)
  end
end
