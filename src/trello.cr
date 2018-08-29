# TODO: Write documentation for `Trello`

require "ncurses"
require "json"
require "http/client"
require "logger"

module Trello
  VERSION = "0.1.0"

  LOG = Logger.new(File.open("log.txt", "w"), level: Logger::DEBUG)

  class App
    SECRETS = JSON.parse(File.read(".secrets.json"))
    CREDENTIALS = "key=#{SECRETS["key"]}&token=#{SECRETS["token"]}"
    MEMBER_ID = SECRETS["memberId"]

    @@windows : Array(Window) = [] of Window

    def self.activate_window(window : Window)
      @@active_window = window
    end

    def self.active_window
      @@active_window || @@windows.find { |w| w.active } || @@windows.first
    end

    def self.add_window(window : Window)
      @@windows << window
    end

    def self.remove_window(window : Window)
      @@windows.delete(window)
    end

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
    API_ROOT = "https://api.trello.com/1/"

    def self.get(path : String, params : String)
      url = "#{API_ROOT}/#{path}?#{App::CREDENTIALS}&#{params}"
      LOG.debug("GETting URL: #{url}")
      response = HTTP::Client.get(url)
      json = JSON.parse(response.body)
      json
    end

    def self.post(path : String, params : String)
      url = "#{API_ROOT}/#{path}?#{App::CREDENTIALS}&#{params}"
      LOG.debug("POSTing URL: #{url}")
      response = HTTP::Client.post(url, body: params)
    end
  end

  class ListSelectOption
    getter key, value

    def initialize(@key : String, @value : String)
    end
  end

  class CardAction
    def initialize(@action : JSON::Any)
    end

    def type
      @action["type"].to_s
    end

    def title
      case type
      when "addMemberToCard"
        "#{creator} added #{member}"
      when "removeMemberFromCard"
        "#{creator} removed #{member}"
      when "commentCard"
        "Comment by #{creator}"
      when "addAttachmentToCard"
        "#{creator} attached #{attachment_name}"
      when "addChecklistToCard"
        "#{creator} added checklist: #{checklist_name}"
      when "deleteAttachmentFromCard"
        "#{creator} detached #{attachment_name}"
      when "createCard"
        "#{creator} created the card"
      when "updateCheckItemStateOnCard"
        "#{creator} marked #{checklist_name}: #{checklist_item} as #{checklist_item_status}"
      else
        LOG.debug("unhandled action: #{type}")
        ""
      end
    end

    def description
      case type
      when "commentCard"
        <<-DESC
        #{@action["data"]["text"]}
        [ #{date} ]
        DESC
      when "addAttachmentToCard"
        if @action["data"]["attachment"].as_h.fetch("url", false)
         <<-DESC
         #{@action["data"]["attachment"]["url"].to_s}
         [ #{date} ]
         DESC
        else
          "[ #{date} ]"
        end
      else
        "[ #{date} ]"
      end
    end

    def creator
      @action["memberCreator"]["username"]
    end

    def member
      @action["member"]["username"]
    end

    def date
      @action["date"]
    end

    def attachment_name
      @action["data"]["attachment"]["name"]
    end

    def checklist_name
      @action["data"]["checklist"]["name"]
    end

    def checklist_item
      @action["data"]["checkItem"]["name"]
    end

    def checklist_item_status
      @action["data"]["checkItem"]["state"]
    end
  end

  class CardDetail
    getter id, name
    property json : JSON::Any = JSON::Any.new("{}")

    HANDLED_TYPES = [
      "addMemberToCard",
      "addAttachmentToCard",
      "addChecklistToCard",
      "commentCard",
      "createCard",
      "deleteAttachmentFromCard",
      "removeMemberFromCard",
      "updateCheckItemStateOnCard",
    ]

    def initialize(@id : String, @name : String, @window : Window)
    end

    def fetch
      @json = API.get("/cards/#{@id}", "members=true&actions=all&actions_limit=1000")
      LOG.debug("Unhandled types: #{@json.as_h["actions"].as_a.reject { |a| HANDLED_TYPES.includes?(a["type"].to_s) }.map{|a| a["type"]}.uniq.join(", ")}")
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
      @json.as_h["actions"].as_a.select { |a| HANDLED_TYPES.includes?(a.["type"].to_s) }
    end

    def add_self_as_member
      response = API.post("/cards/#{@id}/idMembers", "value=#{App::MEMBER_ID}")
      if response.success?
        fetch
      else
        LOG.debug("failed to add self as member: #{response.inspect}")
      end
    end
  end

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
      when '?'
        HelpWindow.new do |win|
          win.link_parent(self)
          win.add_help(key: "a", description: "Add yourself as a member of this card")
        end
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
            # win.attron(NCurses::Attribute::STANDOUT)
            win.attron( App::Colors.blue.attr | NCurses::Attribute::REVERSE)
          else
            win.attron( App::Colors.blue.attr)
          end
        end
        win.addnstr(option.value, @width-2)
        win.attroff(NCurses::Attribute::STANDOUT)
        win.attroff(NCurses::Attribute::BOLD | App::Colors.blue.attr)
        win.attroff(NCurses::Attribute::BOLD | App::Colors.blue.attr | NCurses::Attribute::REVERSE)
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

    def activate!
      super
      if !@path.empty?
        json = API.get(@path, @params)
        json.as_a.each do |j|
          @options << ListSelectOption.new(key: j.as_h["id"].to_s, value: j.as_h["name"].to_s)
        end
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

    def activate!
      if !@path.empty?
        json = API.get(@path, @params)
        json.as_a.sort do |a, b|
          if a["starred"].to_s == "true" && b["starred"].to_s == "false"
            -1
          elsif ["starred"].to_s == "false" && b["starred"].to_s == "true"
            1
          else
            a["name"].to_s <=> b["name"].to_s
          end
        end.each do |j|
          @options << ListSelectOption.new(key: j.as_h["id"].to_s, value: j.as_h["starred"].to_s == "true" ? "★  #{j.as_h["name"]}" : j.as_h["name"].to_s)
        end
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

        pad.refresh(0, 0, @y+2, @x+2, @height, @width)
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

  class CardsWindow < ListSelectWindow
    property list_id : String = ""

    def initialize
      super(x: 27, y: 1, height: NCurses.maxy - 2, width: NCurses.maxx - 28) do |win|
        win.title = "Cards"
      end
    end

    def resize
      @height = NCurses.maxy - 2
      @width = NCurses.maxx - 28
      @win.resize(height: @height, width: @width)
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
      @visible = false
      @win.erase
      @win.refresh
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
      if key == NCurses::KeyCode::RESIZE
        App.windows.each { |w| w.resize }
      else
        App.active_window.handle_key(key)
      end

      NCurses.refresh
      App.windows.select { |w| w.visible }.each { |w| w.refresh }
    end
  end
end
