class CardAction
  def initialize(@action : JSON::Any)
  end

  def type
    @action["type"].to_s
  end

  def title
    case type
    when "addMemberToCard"
      "#{creator} added #{member}"
    when "removeMemberFromCard"
      "#{creator} removed #{member}"
    when "commentCard"
      "Comment by #{creator}"
    when "addAttachmentToCard"
      "#{creator} attached #{attachment_name}"
    when "addChecklistToCard"
      "#{creator} added checklist: #{checklist_name}"
    when "deleteAttachmentFromCard"
      "#{creator} detached #{attachment_name}"
    when "createCard"
      "#{creator} created the card"
    when "updateCheckItemStateOnCard"
      "#{creator} marked #{checklist_name}: #{checklist_item} as #{checklist_item_status}"
    else
      App::LOG.debug("unhandled action: #{type}")
      ""
    end
  end

  def description
    case type
    when "commentCard"
      <<-DESC
      #{@action["data"]["text"]}
      [ #{date} ]
      DESC
    when "addAttachmentToCard"
      if @action["data"]["attachment"].as_h.fetch("url", false)
        <<-DESC
        #{@action["data"]["attachment"]["url"].to_s}
        [ #{date} ]
        DESC
      else
        "[ #{date} ]"
      end
    else
      "[ #{date} ]"
    end
  end

  def creator
    @action["memberCreator"]["username"]
  end

  def member
    @action["member"]["username"]
  end

  def date
    @action["date"]
  end

  def attachment_name
    @action["data"]["attachment"]["name"]
  end

  def checklist_name
    @action["data"]["checklist"]["name"]
  end

  def checklist_item
    @action["data"]["checkItem"]["name"]
  end

  def checklist_item_status
    @action["data"]["checkItem"]["state"]
  end
end
