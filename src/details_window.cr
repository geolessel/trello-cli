require "ncurses"
require "./window"
require "./help_window"
require "./app"
require "./card_action_builder"

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
    @win.attron(NCurses::Attribute::BOLD | App::Colors.blue)
    @win.mvaddstr(title, x: 1, y: 1)
    @win.attroff(NCurses::Attribute::BOLD | App::Colors.blue)
    @win.mvaddstr("Users: #{@card.member_usernames}", x: 1, y: 2)
    @win.mvaddstr("Labels: #{@card.label_names}", x: 1, y: 3)
    @win.refresh

    NCurses::Pad.open(height: 1000, width: @width - 2) do |pad|
      wrap(@card.description, @width - 2).each_line.with_index do |line, i|
        pad.mvaddstr(line.rstrip, x: 0, y: i)
      end
      pad.attron(App::Colors.green)
      pad.addstr("\n\n--|   Attachments   |--\n")
      pad.attroff(App::Colors.green)
      @card.attachments.each do |attachment|
        pad.addstr("#{attachment["name"].to_s}\n")
      end

      pad.attron(App::Colors.green)
      pad.addstr("\n\n--|   Activity   |--\n")
      pad.attroff(App::Colors.green)
      @card.activities.map { |activity| CardActionBuilder.run(activity) }.each do |activity|
        activity.display!(pad, width: @width - 2)
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
    when 'd'
      @row += 10
    when 'u'
      @row -= 10
      if @row < 0
        @row = 0
      end
    when ' '
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
    when 'a'
      AttachmentSelectWindow.new(card_id: @card.id) do |win|
        win.link_parent(self)
        win.on_select = ->(attachment_url : String) do
          `open #{attachment_url}`
          return
        end
      end
    when '?'
      HelpWindow.new do |win|
        win.link_parent(self)
        win.add_help(key: "a", description: "Open an attachment in your browser")
        win.add_help(key: "SPACE", description: "Add yourself as a member of this card")
        win.add_help(key: "shift-l", description: "Add a label to this card")
        win.add_help(key: "m", description: "Move this card to another list")
        win.add_help(key: "o", description: "Open this card in your web browser")
        win.add_help(key: "r", description: "Refresh the details")
        win.add_help(key: "j", description: "Scroll down")
        win.add_help(key: "k", description: "Scroll up")
        win.add_help(key: "l", description: "Select the current item in the list")
        win.add_help(key: "h", description: "Go back")
      end
    end
  end

  def activate!
    super
    @card.fetch
  end
end
