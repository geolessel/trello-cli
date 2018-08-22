# TODO: Write documentation for `Trello`

require "ncurses"

module Trello
  VERSION = "0.1.0"

  class ListSelectWindow
    getter win, height, width, title
    setter options : Array(String)

    setter selected : Int8
    getter selected

    WIDTH = 25
    HEIGHT = 15

    def initialize(x : Int32, y : Int32, height : Int32, width : Int32, title : String)
      @win = NCurses::Window.new(y: y, x: x, height: height, width: width)
      @win.border
      @win.mvaddstr(title, x: 2, y: 0)
      @options = [] of String
      @selected = 0
      @width = width
      @height = height
      @title = title
    end

    def refresh
      y = 0
      @options.each_with_index do |option, i|
        if y >= height-2
          break
        end

        win.move(x: 1, y: y+=1)
        if i == @selected
          win.attron(NCurses::Attribute::STANDOUT)
          win.attron(NCurses::Attribute::BOLD)
        end
        win.addnstr(option, width-2)
        win.attroff(NCurses::Attribute::STANDOUT)
        win.attroff(NCurses::Attribute::BOLD)
      end
      win.refresh
    end

    def handle_key(key)
      case key
      when NCurses::KeyCode::DOWN
        @selected += 1
      when NCurses::KeyCode::UP
        @selected -= 1
      end
    end
  end

  NCurses.open do
    NCurses.start_color
    NCurses.cbreak # CTRL-C breaks the program
    NCurses.noecho # Don't print characters as the user types
    NCurses.curs_set(0) # hide the cursor
    NCurses.keypad(true) # allows arrow and F# keys

    boards = ListSelectWindow.new(x: 1, y: 1, height: 15, width: 25, title: "Boards")
    boards.options = ["Free Week", "People", "People History 2018"]

    lists = ListSelectWindow.new(x: 1, y: 17, height: 15, width: 25, title: "Lists")
    lists.options = ["Bugs", "Queue", "Development", "Staging", "Production"]

    cards = ListSelectWindow.new(x: 27, y: 1, height: NCurses.maxy - 2, width: NCurses.maxx - 28, title: "Cards")
    cards.options = ["Bugs", "Queue", "Development", "Staging", "Production"]

    windows = [boards, lists, cards]

    while true
      NCurses.refresh
      windows.each { |w| w.refresh }

      NCurses.notimeout(true)
      key = NCurses.getch
      boards.handle_key(key)
    end
  end

  # NCurses.open do
  #   NCurses.cbreak
  #   NCurses.noecho
  #   NCurses.keypad(true)
  #
  #   NCurses.box(v: '|', h: '=')
  #   NCurses.mvaddstr("I'm the stdscr. Press any key to quit.", x: 10, y: 5)
  #
  #   NCurses::Window.open(x: 10, y: 5, height: 10, width: 20) do |win|
  #     win.border
  #     win.mvaddstr("Press any key!", x: 1, y: 1)
  #     win.mvaddstr("I'm a subwindow", x: 1, y: 2)
  #     win.mvaddstr("x: #{win.maxx}, y: #{win.maxy}", x: 1, y: 3)
  #     win.refresh
  #     win.notimeout(true)
  #     win.getch
  #   end
  #
  #   NCurses::Pad.open(height: 10, width: 20) do |pad|
  #     pad.border
  #     pad.mvaddstr("I'm a pad", x: 6, y: 4)
  #     pad.refresh(0, 0, 1, 1, 11, 21)
  #     pad.notimeout(true)
  #     pad.getch
  #   end
  #
  #   NCurses.notimeout(true)
  #   NCurses.getch
  # end
end
