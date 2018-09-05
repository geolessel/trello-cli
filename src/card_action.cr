require "./wrap"

class CardAction
  include Wrap

  def initialize(@action : JSON::Any)
  end

  def type
    @action["type"].to_s
  end

  def display!(pad : NCurses::Pad | NCurses::Window, width : Int32)
    case type
    when "commentCard"
      display_title(pad, width)
      display_description(pad, width)
      display_timestamp(pad, width)
    else
      display_title(pad, width)
      pad.addstr(" -- ") unless description.blank?
      display_description(pad, width)
    end
  end


  def display_title(pad : NCurses::Pad | NCurses::Window, width : Int32)
    case type
    when "commentCard"
      pad.attron(NCurses::Attribute::UNDERLINE | App::Colors.yellow)
      wrap(title, width).each_line do |line|
        pad.addstr(line)
        pad.addstr("\n") unless line.ends_with?("\n")
      end
      pad.attroff(NCurses::Attribute::UNDERLINE | App::Colors.yellow)
    else
      wrap(title, width).each_line do |line|
        pad.addstr(line)
        pad.addstr("\n") unless line.ends_with?("\n")
      end
    end
  end

  def display_description(pad : NCurses::Pad | NCurses::Window, width : Int32)
    wrap(description, width).each_line.with_index do |line, i|
      pad.addstr(line)
      pad.addstr("\n") unless line.ends_with?("\n")
    end
  end

  def display_timestamp(pad : NCurses::Pad | NCurses::Window, width : Int32)
    case type
    when "commentCard"
      pad.attron(App::Colors.yellow)
      pad.addstr("--- ")
      pad.attroff(App::Colors.yellow)
    end

    wrap(timestamp, width).each_line.with_index do |line, i|
      pad.addstr(line)
      pad.addstr("\n") unless line.ends_with?("\n")
    end
  end

  def title
    case type
    when "addMemberToCard"
      "#{creator} added #{member}"
    when "removeMemberFromCard"
      "#{creator} removed #{member}"
    when "commentCard"
      "Comment by #{creator}"
    when "addAttachmentToCard"
      "#{creator} attached #{attachment_name}"
    when "addChecklistToCard"
      "#{creator} added checklist: #{checklist_name}"
    when "deleteAttachmentFromCard"
      "#{creator} detached #{attachment_name}"
    when "createCard"
      "#{creator} created the card"
    when "updateCheckItemStateOnCard"
      "#{creator} marked #{checklist_name}: #{checklist_item} as #{checklist_item_status}"
    else
      App::LOG.debug("unhandled action: #{type}")
      ""
    end
  end

  def description
    case type
    when "commentCard"
      @action["data"]["text"].to_s
    when "addAttachmentToCard"
      if @action["data"]["attachment"].as_h.fetch("url", false)
        @action["data"]["attachment"]["url"].to_s
      else
        ""
      end
    else
      ""
    end
  end

  def creator
    @action["memberCreator"]["username"]
  end

  def member
    @action["member"]["username"]
  end

  def date
    @action["date"]
  end

  def timestamp
    "[ #{date} ]"
  end

  def attachment_name
    @action["data"]["attachment"]["name"]
  end

  def checklist_name
    @action["data"]["checklist"]["name"]
  end

  def checklist_item
    @action["data"]["checkItem"]["name"]
  end

  def checklist_item_status
    @action["data"]["checkItem"]["state"]
  end
end
