require "ncurses"
require "./app"

class HelpWindow < Window
  property helps : Array(NamedTuple(key: String, description: String)) = [] of NamedTuple(key: String, description: String)

  def initialize(&block)
    initialize(x: NCurses.maxx / 4, y: NCurses.maxy / 4, height: NCurses.maxy / 2, width: NCurses.maxx / 2) do |win|
      win.title = "Help"
      win.active = true
      yield win
    end
    App.add_window(self)
    App.activate_window(self)
  end

  def initialize(x : Int32, y : Int32, height : Int32, width : Int32, &block)
    initialize(x: x, y: y, height: height, width: width, border: true)
    yield self
  end

  def add_help(key : String, description : String)
    @helps << {key: key, description: description}
  end

  def refresh
    @win.erase
    @win.border
    @win.mvaddstr(@title, x: 2, y: 0) if @title
    @win.refresh

    NCurses::Pad.open(height: 1000, width: @width - 2) do |pad|
      @helps.each do |help|
        pad.attron(App::Colors.green.attr)
        pad.addstr(help[:key])
        pad.attroff(App::Colors.green.attr)

        pad.addstr(" -- ")
        pad.addstr(help[:description])
        pad.addstr("\n")
      end

      pad.refresh(0, 0, @y+2, @x+2, @height, @width + @x - 2)
    end
  end

  def handle_key(_key)
    parent = @parent
    if parent
      App.activate_window(parent)
    end
    App.remove_window(self)
    @win.erase
    @win.close
  end
end
