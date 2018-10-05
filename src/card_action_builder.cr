require "./card_action/*"

class CardActionBuilder
  def self.run(action : JSON::Any)
    klass = case action["type"].to_s
            when "commentCard"
              Comment
            when "addMemberToCard"
              AddMemberToCard
            when "addAttachmentToCard"
              AddAttachmentToCard
            when "addChecklistToCard"
              AddChecklistToCard
            when "removeMemberFromCard"
              RemoveMemberFromCard
            when "deleteAttachmentFromCard"
              DeleteAttachmentFromCard
            when "createCard"
              CreateCard
            when "updateCard"
              if action["data"].as_h.fetch("listBefore", false)
                MoveCard
              else
                BlankCard
              end
            when "updateCheckItemStateOnCard"
              UpdateCheckItemStateOnCard
            else
              CardAction
            end
    klass.new(action)
  end
end
