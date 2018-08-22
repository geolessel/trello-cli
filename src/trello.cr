# TODO: Write documentation for `Trello`

require "ncurses"

module Trello
  VERSION = "0.1.0"

  class ListSelectWindow
    getter win, height, width, title, parent, child, selected, active

    setter lines : Array(String)
    setter selected : Int8
    setter active : Bool

    WIDTH = 25
    HEIGHT = 15

    def initialize(x : Int32, y : Int32, height : Int32, width : Int32, title : String)
      @win = NCurses::Window.new(y: y, x: x, height: height, width: width)
      @lines = [] of String
      @selected = 0
      @width = width
      @height = height
      @title = title
      @active = false
    end

    def refresh
      win.border
      win.mvaddstr(title, x: 2, y: 0)

      y = 0
      @lines.each_with_index do |option, i|
        if y >= height-2
          break
        end

        win.move(x: 1, y: y+=1)

        if i == @selected
          if @active
            win.attron(NCurses::Attribute::STANDOUT)
          end
        end
        win.addnstr(option, width-2)
        win.attroff(NCurses::Attribute::STANDOUT)
      end
      win.refresh
    end

    def handle_key(key)
      case key
      when NCurses::KeyCode::DOWN, 'j'
        if @selected < @lines.size - 1
          @selected += 1
        end
      when NCurses::KeyCode::UP, 'k'
        if @selected > 0
          @selected -= 1
        end
      when NCurses::KeyCode::RETURN, NCurses::KeyCode::RIGHT, 'l'
        child = @child
        if child
          @active = false
          child.active = true
        end
      when NCurses::KeyCode::LEFT, 'q', 'h' # Q, J
        parent = @parent
        if parent
          @active = false
          parent.active = true
        end
      else
        @lines << "#{key}"
      end
    end

    def link_parent(parent : ListSelectWindow)
      @parent = parent
      parent.link_child(self)
    end

    def link_child(child : ListSelectWindow)
      @child = child
    end

    def active?
      @active
    end
  end

  NCurses.open do
    NCurses.start_color
    NCurses.cbreak # CTRL-C breaks the program
    NCurses.noecho # Don't print characters as the user types
    NCurses.curs_set(0) # hide the cursor
    NCurses.keypad(true) # allows arrow and F# keys

    boards = ListSelectWindow.new(x: 1, y: 1, height: 15, width: 25, title: "Boards")
    boards.lines = ["Free Week", "People", "People History 2018"]
    boards.active = true

    lists = ListSelectWindow.new(x: 1, y: 17, height: 15, width: 25, title: "Lists")
    lists.lines = ["Free Week", "People", "People History 2018"]
    lists.link_parent(boards)

    cards = ListSelectWindow.new(x: 27, y: 1, height: NCurses.maxy - 2, width: NCurses.maxx - 28, title: "Cards")
    cards.lines = ["Free Week", "People", "People History 2018"]
    cards.link_parent(lists)

    windows = [boards, lists, cards]

    selected = 0

    NCurses.refresh
    windows.each { |w| w.refresh }

    while true
      NCurses.notimeout(true)
      key = NCurses.getch
      windows.find(boards) { |w| w.active }.handle_key(key)

      NCurses.refresh
      windows.each { |w| w.refresh }
    end
  end
end
