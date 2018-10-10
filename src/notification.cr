require "./api"
require "./app"

class Notification
  SYMBOL = "🔔"

  def initialize(@data : JSON::Any)
  end

  def card_id
    return "" unless @data["data"]?
    return "" unless @data["data"]["card"]?
    @data["data"]["card"]["id"].to_s
  end

  def unread?
    @data["unread"].as_bool
  end

  def render(win)
    win.addstr(SYMBOL)
    win.addstr(" ")
  end

  def self.fetch
    json = API.get("members/me/notifications", "read_filter=unread&limit=1000")
    App.notifications = json.as_a.each_with_object({} of String => Notification) do |notification, hash|
      n = Notification.new(notification)
      hash[n.card_id] = n unless n.card_id.blank?
    end
  end

  def self.fetch_async
    spawn do
      json = API.get("members/me/notifications", "read_filter=unread&limit=1000")
      App.notifications = json.as_a.each_with_object({} of String => Notification) do |notification, hash|
        n = Notification.new(notification)
        hash[n.card_id] = n unless n.card_id.blank?
      end
    end
    Fiber.yield
  end
end
