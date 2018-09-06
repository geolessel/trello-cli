require "../wrap"
require "./card_action"

class Comment < CardAction
  include Wrap

  def initialize(@action : JSON::Any)
  end

  def display!(pad : NCurses::Pad | NCurses::Window, width : Int32)
    display_title(pad, width)
    display_description(pad, width)
    display_timestamp(pad, width)
  end

  def display_title(pad : NCurses::Pad | NCurses::Window, width : Int32)
    pad.attron(NCurses::Attribute::UNDERLINE | App::Colors.yellow)
    wrap(title, width).each_line do |line|
      pad.addstr(line)
      pad.addstr("\n") unless line.ends_with?("\n")
    end
    pad.attroff(NCurses::Attribute::UNDERLINE | App::Colors.yellow)
  end

  def display_description(pad : NCurses::Pad | NCurses::Window, width : Int32)
    wrap(description, width).each_line.with_index do |line, i|
      pad.addstr(line)
      pad.addstr("\n") unless line.ends_with?("\n")
    end
  end

  def display_timestamp(pad : NCurses::Pad | NCurses::Window, width : Int32)
    pad.attron(App::Colors.yellow)
    pad.addstr("--- ")
    pad.attroff(App::Colors.yellow)

    wrap(timestamp, width).each_line.with_index do |line, i|
      pad.addstr(line)
      pad.addstr("\n") unless line.ends_with?("\n")
    end
  end

  def title
    "Comment by #{creator}"
  end

  def description
    @action["data"]["text"].to_s
  end
end
