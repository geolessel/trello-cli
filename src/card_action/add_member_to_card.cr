require "./card_action"

class AddMemberToCard < CardAction
  def title
    "#{creator} added #{member}"
  end
end
