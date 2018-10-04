require "./card_action"

class UpdateCard < CardAction
  def title
    "#{creator} moved the card: #{before_list} -> #{after_list}"
  end

  def before_list
    @action["data"]["listBefore"]["name"]
  end

  def after_list
    @action["data"]["listAfter"]["name"]
  end
end
