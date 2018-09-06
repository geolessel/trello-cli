require "./card_action"

class AddAttachmentToCard < CardAction
  def title
    "#{creator} attached \"#{attachment_name}\""
  end
end
