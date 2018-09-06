require "./card_action"

class AddChecklistToCard < CardAction
  def title
    "#{creator} added checklist \"#{checklist_name}\""
  end
end
