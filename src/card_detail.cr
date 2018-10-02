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

  def add_self_as_member
    response = API.post("/cards/#{@id}/idMembers", "value=#{App.member_id}")
    if response.success?
      fetch
    else
      App.log.debug("failed to add self as member: #{response.inspect}")
    end
  end

  def add_label(label_id : String)
    response = API.post("/cards/#{@id}/idLabels", "value=#{label_id}")
    if response.success?
      fetch
    else
      App.log.debug("failed to add label to card: #{response.inspect}")
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
    File.delete(App.comment_temp_file_path) if File.exists?(App.comment_temp_file_path)

    Process.run(ENV["EDITOR"], args: {App.comment_temp_file_path}, output: STDOUT, input: STDIN, error: STDERR, shell: true)

    App.reset_screen

    unless !File.exists?(App.comment_temp_file_path) || File.empty?(App.comment_temp_file_path)
      comment_text = File.read(App.comment_temp_file_path)
      API.post("/cards/#{@id}/actions/comments", form: { "text" => comment_text })
      fetch
    end
  end
end
