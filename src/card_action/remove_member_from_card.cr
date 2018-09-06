require "./card_action"

class RemoveMemberFromCard < CardAction
  def title
    "#{creator} removed #{member}"
  end
end
