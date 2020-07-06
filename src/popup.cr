require "ncurses"
require "./app"
require "./window"

class Popup < Window
  include Wrap

  property on_close : Proc(Void) = -> {}
  property text : String = ""

  def initialize(x = NCurses.maxx // 4, y = NCurses.maxy // 4, height = NCurses.maxy // 2, width = NCurses.maxx // 2, &block)
    initialize(x: x, y: y, height: height, width: width) do |win|
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

  def refresh
    @win.erase
    @win.border
    @win.mvaddstr(@title, x: 2, y: 0) if @title
    @win.refresh

    NCurses::Pad.open(height: 1000, width: @width - 2) do |pad|
      pad.addstr(wrap(@text, @width - 2))
      pad.refresh(0, 0, @y+2, @x+2, @height, @width + @x - 2)
    end
  end

  def handle_key(key)
    case key
    when 'q', 'Q'
      release
    else
      @on_close.call()
      release
    end
  end

  def release
    parent = @parent
    if parent
      App.activate_window(parent)
    end
    App.remove_window(self)
    @win.erase
    @win.close
  end
end
