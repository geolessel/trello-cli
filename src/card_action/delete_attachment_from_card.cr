require "./card_action"

class DeleteAttachmentFromCard < CardAction
  def title
    "#{creator} detached \"#{attachment_name}\""
  end
end
