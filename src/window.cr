require "ncurses"
require "./app"

abstract class Window
  property active : Bool = false
  property title : String = ""
  property visible : Bool = true
  property height : Int32
  property width : Int32
  property border : Bool = false
  getter x, y, win

  def initialize(@x : Int32, @y : Int32, @height : Int32, @width : Int32, @border : Bool = false)
    @win = NCurses::Window.new(y: @y, x: @x, height: @height, width: @width)
  end

  def refresh
    @win.erase
    @win.border if @border
    @win.mvaddstr(@title, x: 2, y: 0) if @title
    @win.refresh
  end

  def link_parent(parent : Window)
    @parent = parent
    parent.link_child(self)
  end

  def link_child(child : Window)
    @child = child
  end

  def activate_parent!
    # you can't get a truthy value out of an instance variable
    parent = @parent
    if parent
      @active = false
      parent.active = true
      parent.visible = true
      App.activate_window(parent)
    end
  end

  def activate_child!(option)
  end

  def active?
    @active
  end

  def activate!
    App.activate_window(self)
    @active = true
  end

  def resize
    # noop
  end
end
