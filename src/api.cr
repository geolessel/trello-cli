require "http/client"
require "json"
require "./app"

class API
  API_ROOT = "https://api.trello.com/1/"

  def self.get(path : String, params : String)
    url = "#{API_ROOT}/#{path}?#{App.credentials}&#{params}"
    App.log.debug("GETting URL: #{url}")
    response = HTTP::Client.get(url)
    json = JSON.parse(response.body)
    json
  end

  def self.post(path : String, params : String = "", form : String | IO | Hash = "")
    url = "#{API_ROOT}/#{path}?#{App.credentials}&#{params}"
    App.log.debug("POSTing URL: #{url}")
    response = HTTP::Client.post(url, form: form)
  end

  def self.put(path : String, params : String)
    url = "#{API_ROOT}/#{path}?#{App.credentials}&#{params}"
    App.log.debug("PUTting URL: #{url}")
    response = HTTP::Client.put(url)
  end

  def self.delete(path : String, params : String = "")
    url = "#{API_ROOT}/#{path}?#{App.credentials}&#{params}"
    App.log.debug("DELETEing URL: #{url}")
    response = HTTP::Client.delete(url)
  end
end
