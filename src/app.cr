require "ncurses"
require "logger"

class App
  SECRETS = JSON.parse(File.read("#{ENV["HOME"]}/.trello-cli/secrets.json"))
  CREDENTIALS = "key=3020057fffe933d81fe081eb4f8d126a&token=#{SECRETS["token"]}"
  MEMBER_ID = SECRETS["memberId"]

  LOG = Logger.new(File.open("log.txt", "w"), level: Logger::DEBUG)

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
