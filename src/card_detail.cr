require "./app"
require "./api"
require "./editor"

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

  def initialize(@id : String, @name : String)
  end

  def fetch
    @json = API.get("/cards/#{@id}", "members=true&attachments=true&actions=all&actions_limit=1000")
    # App::LOG.debug("Unhandled types: #{@json.as_h["actions"].as_a.reject { |a| HANDLED_TYPES.includes?(a["type"].to_s) }.map{|a| a["type"]}.uniq.join(", ")}")
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

  def attachments
    @json.as_h["attachments"].as_a
  end

  def board_id
    @json.as_h["idBoard"].to_s
  end

  def short_url
    @json.as_h["shortUrl"].to_s
  end

  def add_or_remove_self_as_member
    response =
      if @json.as_h["members"].as_a.find { |l| l["id"] == App.member_id }
        API.delete("/cards/#{@id}/idMembers/#{App.member_id}")
      else
        API.post("/cards/#{@id}/idMembers", "value=#{App.member_id}")
      end
    if response.success?
      fetch
    else
      App.log.debug("failed to manage user as member: #{response.inspect}")
    end
  end

  def manage_label(label_id : String)
    response =
      if @json.as_h["labels"].as_a.find { |l| l["id"] == label_id }
        API.delete("/cards/#{@id}/idLabels/#{label_id}")
      else
        API.post("/cards/#{@id}/idLabels", "value=#{label_id}")
      end

    if response.success?
      fetch
    else
      App.log.debug("failed to manage label on card: #{response.inspect}")
    end
  end

  def move_to_list(list_id : String)
    response = API.put("cards/#{@id}/idList", "value=#{list_id}")
    if response.success?
      fetch
    else
      App.log.debug("failed to move card to list: #{response.inspect}")
    end
  end

  def add_comment
    Editor.run do |comment|
      API.post("/cards/#{@id}/actions/comments", form: { "text" => comment })
      fetch
    end
  end

  def archive
    response = API.put("cards/#{@id}", "closed=true")
    if response.success?
      fetch
    else
      App.log.debug("failed to archive card: #{response.inspect}")
    end
  end

  def add_attachment
    Editor.run(contents: "{\n  \"name\": \"\",\n  \"url\": \"\"\n}") do |json|
      att = JSON.parse(json)
      API.post("/cards/#{@id}/attachments", form: "name=#{att["name"]}&url=#{att["url"]}")
      fetch
    end
  end
end
