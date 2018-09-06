require "./create_card"

class CreateCard < CardAction
  def title
    "#{creator} created the card"
  end
end
