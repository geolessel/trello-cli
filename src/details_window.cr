require "ncurses"
require "./window"
require "./help_window"
require "./app"

class DetailsWindow < Window
  property row : Int32 = 0

  def initialize(@card : CardDetail)
    initialize(x: 27, y: 1, height: 5, width: NCurses.maxx - 28) do |win|
      win.title = card.name
    end
    App.windows << self
  end

  def initialize(x : Int32, y : Int32, height : Int32, width : Int32, &block)
    initialize(x: x, y: y, height: height, width: width)
    yield self
  end

  def resize
    @width = NCurses.maxx - 28
    @win.resize(height: @height, width: @width)
  end

  def refresh
    @win.erase
    @win.border
    @win.attron(NCurses::Attribute::BOLD | App::Colors.blue.attr)
    @win.mvaddstr(title, x: 1, y: 1)
    @win.attroff(NCurses::Attribute::BOLD | App::Colors.blue.attr)
    @win.mvaddstr("Users: #{@card.member_usernames}", x: 1, y: 2)
    @win.mvaddstr("Labels: #{@card.label_names}", x: 1, y: 3)
    @win.refresh

    NCurses::Pad.open(height: 1000, width: @width - 2) do |pad|
      pad.mvaddstr(@card.description, x: 0, y: 0)
      pad.attron(App::Colors.green.attr)
      pad.addstr("\n\n--|   ACTIVITY   |--")
      pad.addstr((21..@width - 2).map { "-" }.join)
      pad.attroff(App::Colors.green.attr)
      pad.addstr("\n\n")
      @card.activities.map { |activity| CardAction.new(activity) }.each do |activity|
        pad.attron(NCurses::Attribute::BOLD | NCurses::Attribute::UNDERLINE)
        pad.addstr(activity.title)
        pad.attroff(NCurses::Attribute::BOLD | NCurses::Attribute::UNDERLINE)
        pad.addstr("\n")
        pad.addstr(activity.description)
        pad.addstr("\n\n\n")
      end
      pad.refresh(@row, 0, 6, 28, NCurses.maxy - 3, NCurses.maxx - 2)
    end
  end

  def handle_key(key)
    case key
    when NCurses::KeyCode::LEFT, 'q', 'h'
      @win.erase
      @win.close
      activate_parent!
      App.remove_window(self)
    when NCurses::KeyCode::UP, 'k'
      @row -= 1
      if @row < 0
        @row = 0
      end
    when NCurses::KeyCode::DOWN, 'j'
      @row += 1
    when ' ', 'd'
      @row += 10
    when 'u'
      @row -= 10
      if @row < 0
        @row = 0
      end
    when 'a'
      @card.add_self_as_member
    when 76, 'L'
      LabelSelectWindow.new(board_id: @card.board_id) do |win|
        win.link_parent(self)
        win.on_select = ->(label_id : String) do
          @card.add_label(label_id)
          return
        end
      end
    when 'o'
      `open #{@card.short_url}`
    when 'm'
      ListSelectWindow.new(board_id: @card.board_id) do |win|
        win.link_parent(self)
        win.on_select = ->(list_id : String) do
          @card.move_to_list(list_id)
          return
        end
      end
    when '?'
      HelpWindow.new do |win|
        win.link_parent(self)
        win.add_help(key: "a", description: "Add yourself as a member of this card")
        win.add_help(key: "m", description: "Move this card to another list")
        win.add_help(key: "o", description: "Open this card in your web browser")
        win.add_help(key: "shift-l", description: "Add a label to this card")
      end
    end
  end

  def activate!
    super
    @card.fetch
  end
end
