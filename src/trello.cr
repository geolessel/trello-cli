# TODO: Write documentation for `Trello`

require "ncurses"
require "json"
require "http/client"
require "logger"

module Trello
  VERSION = "0.1.0"

  LOG = Logger.new(File.open("log.txt", "w"), level: Logger::DEBUG)

  class App
    @@windows : Array(Window) = [] of Window

    def self.windows=(windows : Array(Window))
      @@windows = windows
    end

    def self.windows
      @@windows
    end

    module Colors
      extend self

      def cyan
        NCurses::ColorPair.new(1).init(NCurses::Color::CYAN, NCurses::Color::BLACK)
      end

      def blue
        NCurses::ColorPair.new(2).init(NCurses::Color::BLUE, NCurses::Color::BLACK)
      end

      def green
        NCurses::ColorPair.new(3).init(NCurses::Color::GREEN, NCurses::Color::BLACK)
      end
    end
  end

  class API
    SECRETS = JSON.parse(File.read(".secrets.json"))
    API_ROOT = "https://api.trello.com/1/"
    CREDENTIALS = "key=#{SECRETS["key"]}&token=#{SECRETS["token"]}"

    def self.get(path : String, params : String)
      url = "#{API_ROOT}/#{path}?#{CREDENTIALS}&#{params}"
      LOG.debug("Fetching URL: #{url}")
      response = HTTP::Client.get(url)
      json = JSON.parse(response.body)
      LOG.debug("Fetched: #{json}")
      json
    end
  end

  class ListSelectOption
    getter key, value

    def initialize(@key : String, @value : String)
    end
  end

  class CardDetail
    getter id, name
    property json : JSON::Any = JSON::Any.new("{}")

    def initialize(@id : String, @name : String, @window : Window)
    end

    def fetch
      @json = API.get("/cards/#{@id}", "members=true&actions=all&actions_limit=1000")
    end

    def member_usernames
      @json.as_h["members"].as_a.map { |m| m["username"].to_s }.join(", ")
    end

    def label_names
      @json.as_h["labels"].as_a.map { |l| l["name"].to_s }.join(", ")
    end

    def description
      @json.as_h["desc"].to_s
    end

    def activities
      str = @json.as_h["actions"].as_a.map { |action| action_string(action) }.compact
      str = str.join("\n\n\n")
    end

    def action_string(action)
      case action["type"].to_s
      when "commentCard"
        LOG.debug("Comment: #{action["data"]["text"].to_s}")
        "--[ Comment by #{action["memberCreator"]["username"]} at #{action["date"]} ]--\n#{action["data"]["text"].to_s}"
      else
        LOG.debug("unhandled action: #{action["type"].to_s}")
      end
    end
  end

  abstract class Window
    property active : Bool = false
    property title : String = ""
    getter height, width, x, y, win

    def initialize(@x : Int32, @y : Int32, @height : Int32, @width : Int32)
      @win = NCurses::Window.new(y: @y, x: @x, height: @height, width: @width)
    end

    def refresh
      @win.refresh
    end

    def link_parent(parent : Window)
      @parent = parent
      parent.link_child(self)
    end

    def activate_parent!
      # you can't get a truthy value out of an instance variable
      parent = @parent
      if parent
        @active = false
        parent.active = true
      end
    end

    def activate_child!(option)
    end

    def active?
      @active
    end

    def activate!
      @active = true
    end
  end

  class DetailsWindow < Window
    def initialize(@card : CardDetail)
      initialize(x: 27, y: 1, height: NCurses.maxy - 2, width: NCurses.maxx - 28) do |win|
        win.title = card.name
      end
      App.windows << self
    end

    def initialize(x : Int32, y : Int32, height : Int32, width : Int32, &block)
      initialize(x: x, y: y, height: height, width: width)
      yield self
    end

    def refresh
      @win.erase
      @win.border
      @win.attron(NCurses::Attribute::BOLD | App::Colors.blue.attr)
      @win.mvaddstr(title, x: 1, y: 1)
      @win.attroff(NCurses::Attribute::BOLD | App::Colors.blue.attr)
      @win.mvaddstr("Users: #{@card.member_usernames}", x: 1, y: 2)
      @win.mvaddstr("Labels: #{@card.label_names}", x: 1, y: 3)
      @win.mvhline(n: NCurses.maxx - 30, x: 1, y: 4, ch: '=')
      NCurses::Window.derwin(parent: @win, x: 1, y: 5, height: @height - 5, width: @width - 2) do |sub|
        sub.mvaddstr(@card.description, x: 0, y: 1)
        sub.attron(App::Colors.green.attr)
        sub.addstr("\n\n--[   ACTIVITY   ]--")
        sub.addstr((21..@width - 2).map { "-" }.join)
        sub.attroff(App::Colors.green.attr)
        sub.addstr("\n\n")
        sub.addstr(@card.activities)
      end
      @win.refresh
    end

    def handle_key(key)
      case key
      when NCurses::KeyCode::LEFT, 'q', 'h'
        @win.erase
        @win.close
        activate_parent!
        App.windows.delete(self)
      end
    end

    def activate!
      super
      @card.fetch
    end
  end

  abstract class ListSelectWindow < Window
    getter win, height, width, title, parent, child, selected, active, json

    setter selected : Int8
    setter active : Bool
    setter title : String
    setter path : String
    setter params : String
    setter options : Array(ListSelectOption)
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
      @options = [] of ListSelectOption
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
            win.attron(NCurses::Attribute::STANDOUT)
          else
            win.attron(NCurses::Attribute::BOLD | App::Colors.blue.attr)
          end
        end
        win.addnstr(option.value, width-2)
        win.attroff(NCurses::Attribute::STANDOUT)
        win.attroff(NCurses::Attribute::BOLD | App::Colors.blue.attr)
      end

      win.refresh
    end

    def handle_key(key)
      case key
      when NCurses::KeyCode::DOWN, 'j'
        if @selected < height-3
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
      else
        LOG.debug("Unhandled key: #{key}")
      end
    end

    def link_child(child : Window)
      @child = child
    end

    def activate!
      super
      if !@path.empty?
        json = API.get(@path, @params)
        json.as_a.each do |j|
          @options << ListSelectOption.new(key: j.as_h["id"].to_s, value: j.as_h["name"].to_s)
        end
        @options << ListSelectOption.new(key: "💩", value: "💩")
      end
    end

    def handle_select_previous
      @options = [] of ListSelectOption
      @selected = 0
      activate_parent!
    end

    def handle_select_next(selected)
      activate_child!(selected)
    end
  end

  class BoardsWindow < ListSelectWindow
    def initialize
      super(x: 1, y: 1, height: 15, width: 25) do |win|
        win.path = "members/me/boards"
        win.params = "fields=name,starred,shortUrl"
        win.active = true
        win.title = "Boards"
      end
    end

    def activate_child!(option : ListSelectOption)
      # you can't get a truthy value out of an instance variable
      child = @child
      if child
        @active = false
        child.set_board_id(option.key) if child.is_a? ListsWindow
        child.activate!
      end
    end
  end

  class ListsWindow < ListSelectWindow
    property board_id : String = ""

    def initialize
      super(x: 1, y: 17, height: 15, width: 25) do |win|
        win.title = "Lists"
      end
    end

    def set_board_id(id : String)
      @path = "boards/#{id}/lists"
      @params = "fields=name,shortUrl"
    end

    def activate_child!(option : ListSelectOption)
      child = @child
      if child
        @active = false
        child.set_list_id(option.key) if child.is_a? CardsWindow
        child.activate!
      end
    end
  end

  class CardsWindow < ListSelectWindow
    property list_id : String = ""

    def initialize
      super(x: 27, y: 1, height: NCurses.maxy - 2, width: NCurses.maxx - 28) do |win|
        win.title = "Cards"
      end
    end

    def set_list_id(id : String)
      @path = "lists/#{id}/cards"
      @params = "fields=name,shortUrl"
    end

    def handle_select_next(selected)
      card = CardDetail.new(id: selected.key, name: selected.value, window: self)

      details = DetailsWindow.new(card: card)
      details.link_parent(self)
      details.activate!
      @active = false
    end
  end

  LibNCurses.setlocale(0, "") # enable unicode
  NCurses.open do
    NCurses.start_color
    NCurses.cbreak # CTRL-C breaks the program
    NCurses.noecho # Don't print characters as the user types
    NCurses.curs_set(0) # hide the cursor
    NCurses.keypad(true) # allows arrow and F# keys

    boards = BoardsWindow.new
    boards.activate!

    lists = ListsWindow.new
    lists.link_parent(boards)

    cards = CardsWindow.new
    cards.link_parent(lists)

    App.windows = [boards, lists, cards] of Window

    NCurses.refresh
    App.windows.each { |w| w.refresh }

    while true
      NCurses.notimeout(true)
      key = NCurses.getch
      active_window = App.windows.find(boards) { |w| w.active }
      active_window.handle_key(key)

      NCurses.refresh
      App.windows.each { |w| w.refresh }
    end
  end
end
