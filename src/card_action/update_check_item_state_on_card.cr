require "./card_action"

class UpdateCheckItemStateOnCard < CardAction
  def title
    "#{creator} marked \"#{checklist_item}\" from \"#{checklist_name}\" as #{checklist_item_status}"
  end
end
