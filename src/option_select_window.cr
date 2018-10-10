require "ncurses"
require "./app"
require "./window"
require "./option_select_option"

class OptionSelectWindow < Window
  getter win, height, width, title, parent, child, selected, active, json

  setter selected : Int8
  setter active : Bool
  setter title : String
  setter path : String
  setter params : String
  setter options : Array(OptionSelectOption)
  setter board_id : String = ""

  property row_offset : Int32 = 0

  WIDTH = 25
  HEIGHT = 15

  def initialize(@x : Int32, @y : Int32, @height : Int32, @width : Int32)
    @win = NCurses::Window.new(y: @y, x: @x, height: @height, width: @width)
    @selected = 0
    @title = ""
    @active = false
    @path = ""
    @params = ""
    @options = [] of OptionSelectOption
  end

  def initialize(@x : Int32, @y : Int32, @height : Int32, @width : Int32, &block)
    initialize(x: @x, y: @y, height: @height, width: @width)
    yield self
  end

  def refresh
    win.erase
    win.border
    win.mvaddstr(title, x: 2, y: 0)

    y = 0

    @options[@row_offset..height+@row_offset].each_with_index do |option, i|
      if y >= height-2
        break
      end

      win.move(x: 1, y: y+=1)

      if i == @selected
        if @active
          win.attron(App::Colors.blue | NCurses::Attribute::REVERSE)
        else
          win.attron(App::Colors.blue)
        end
      end
      render_row(option)
      win.attroff(App::Colors.blue | NCurses::Attribute::REVERSE)
    end

    win.refresh
  end

  def render_row(option)
    win.addnstr(option.value, @width-2)
  end

  def handle_key(key)
    case key
    when NCurses::KeyCode::DOWN, 'j'
      if @selected < height-3 && @options.size > @selected + 1
        @selected += 1
      elsif @row_offset + height <= @options.size + 1
        @row_offset += 1
      end
    when NCurses::KeyCode::UP, 'k'
      if @selected > 0
        @selected -= 1
      elsif @row_offset > 0
        @row_offset -= 1
      end
    when NCurses::KeyCode::RETURN, NCurses::KeyCode::RIGHT, 'l'
      handle_select_next(@options[@selected + @row_offset])
    when NCurses::KeyCode::LEFT, 'q', 'h' # Q, J
      handle_select_previous
    when 'r'
      fetch
    when '?'
      HelpWindow.new do |win|
        win.link_parent(self)
        add_helps(win)
      end
    else
      App.log.debug("Unhandled key: #{key}")
    end
  end

  def add_helps(win)
    win.add_help(key: "r", description: "Refresh the data in the active pane from Trello")
    win.add_help(key: "j", description: "Scroll down")
    win.add_help(key: "k", description: "Scroll up")
    win.add_help(key: "l", description: "Select the current item in the list")
    win.add_help(key: "h", description: "Go back")
  end

  def activate!
    super
    fetch
  end

  def fetch
    if !@path.empty?
      @options = [] of OptionSelectOption
      json = API.get(@path, @params)
      json.as_a.each do |j|
        @options << OptionSelectOption.new(key: j.as_h["id"].to_s, value: render_option_value(j), json: j)
      end
    end
  end

  def render_option_value(json : JSON::Any)
    json.as_h["name"].to_s
  end

  def handle_select_previous
    @options = [] of OptionSelectOption
    @selected = 0
    activate_parent!
  end

  def handle_select_next(selected)
    activate_child!(selected)
  end
end
