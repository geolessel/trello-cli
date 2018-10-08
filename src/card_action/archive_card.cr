require "./card_action"

class ArchiveCard < CardAction
  def title
    "#{creator} #{action} the card"
  end

  def action
    @action["data"]["old"]["closed"] == true ? "unarchived" : "archived"
  end
end
