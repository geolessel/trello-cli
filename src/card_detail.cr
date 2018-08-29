require "./app"
require "./api"

class CardDetail
  getter id, name
  property json : JSON::Any = JSON::Any.new("{}")

  HANDLED_TYPES = [
    "addMemberToCard",
    "addAttachmentToCard",
    "addChecklistToCard",
    "commentCard",
    "createCard",
    "deleteAttachmentFromCard",
    "removeMemberFromCard",
    "updateCheckItemStateOnCard",
  ]

  def initialize(@id : String, @name : String, @window : Window)
  end

  def fetch
    @json = API.get("/cards/#{@id}", "members=true&actions=all&actions_limit=1000")
    App::LOG.debug("Unhandled types: #{@json.as_h["actions"].as_a.reject { |a| HANDLED_TYPES.includes?(a["type"].to_s) }.map{|a| a["type"]}.uniq.join(", ")}")
  end

  def member_usernames
    @json.as_h["members"].as_a.map { |m| m["username"].to_s }.join(", ")
  end

  def label_names
    @json.as_h["labels"].as_a.map { |l| l["name"].to_s }.join(", ")
  end

  def description
    @json.as_h["desc"].to_s
  end

  def activities
    @json.as_h["actions"].as_a.select { |a| HANDLED_TYPES.includes?(a.["type"].to_s) }
  end

  def board_id
    @json.as_h["idBoard"].to_s
  end

  def add_self_as_member
    response = API.post("/cards/#{@id}/idMembers", "value=#{App::MEMBER_ID}")
    if response.success?
      fetch
    else
      App::LOG.debug("failed to add self as member: #{response.inspect}")
    end
  end

  def add_label(label_id : String)
    response = API.post("/cards/#{@id}/idLabels", "value=#{label_id}")
    if response.success?
      fetch
    else
      App::LOG.debug("failed to add label to card: #{response.inspect}")
    end
  end
end
