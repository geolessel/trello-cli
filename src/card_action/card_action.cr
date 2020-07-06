require "../wrap"

class CardAction
  include Wrap

  def initialize(@action : JSON::Any)
  end

  def type
    @action["type"].to_s
  end

  def display!(pad : NCurses::Pad | NCurses::Window, width : Int32)
    display_title(pad, width)
    pad.addstr(" -- ") unless description.blank?
    display_description(pad, width)
    display_timestamp(pad, width)
    pad.addstr("\n\n\n")
  end

  def display_title(pad : NCurses::Pad | NCurses::Window, width : Int32)
    wrap(title, width).each_line do |line|
      pad.addstr(line)
      pad.addstr("\n") unless line.ends_with?("\n")
    end
  end

  def display_description(pad : NCurses::Pad | NCurses::Window, width : Int32)
    wrap(description, width).each_line.with_index do |line, i|
      pad.addstr(line)
      pad.addstr("\n") unless line.ends_with?("\n")
    end
  end

  def display_timestamp(pad : NCurses::Pad | NCurses::Window, width : Int32)
    pad.addstr(timestamp)
  end

  def title
    App.log.debug { "unhandled action: #{type}" }
    ""
  end

  def description
    ""
  end

  def creator
    @action["memberCreator"]["username"]
  end

  def member
    @action["member"]["username"]
  end

  def date
    Time.parse_iso8601(@action["date"].to_s)
  end

  def timestamp
    date.to_s("%Y-%m-%d @ %I:%M%p %:z")
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
