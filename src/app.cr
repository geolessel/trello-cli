require "ncurses"
require "log"

class App
  CONFIG_DIR = "#{ENV["HOME"]}/.trello-cli"
  APP_KEY = "3020057fffe933d81fe081eb4f8d126a"

  @@windows : Array(Window) = [] of Window
  @@member_id : String = ""
  @@secrets : JSON::Any = JSON::Any.new("{}")
  @@token : String | Nil = ""
  @@card_labels : Hash(String, String) = {} of String => String
  @@log : Log = ::Log.for("trello")
  @@notifications : Hash(String, Array(Notification)) = {} of String => Array(Notification)

  def self.init
    @@secrets = JSON.parse(File.read("#{CONFIG_DIR}/secrets.json"))
    @@token = App.secrets["token"].to_s
    @@member_id = @@secrets["memberId"].to_s
    @@secrets.as_h.has_key?("cardLabels") && @@secrets["cardLabels"].as_h
      .each do |k, v|
        @@card_labels[k.to_s] = v.to_s
      end
    Log.setup(level: :debug, backend: Log::IOBackend.new(File.open("#{CONFIG_DIR}/log.txt", "w")))
  end

  def self.setup_ncurses
    NCurses.clear
    NCurses.erase
    NCurses.start_color
    # NCurses.use_default_colors
    NCurses.cbreak # CTRL-C breaks the program
    NCurses.noecho # Don't print characters as the user types
    NCurses.curs_set(0) # hide the cursor
    NCurses.keypad(true) # allows arrow and F# keys
  end

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

  def self.notifications=(notifications : Hash(String, Array(Notification)))
    @@notifications = notifications
  end

  def self.notifications
    @@notifications
  end

  def self.credentials
    "key=#{APP_KEY}&token=#{@@token}"
  end

  def self.member_id
    @@member_id
  end

  def self.secrets
    @@secrets
  end

  def self.log
    @@log
  end

  def self.card_labels
    @@card_labels
  end

  def self.run_setup
    Setup.make_config_dir
    Setup.make_templates
    Setup.display_intro_text
    @@token = Setup.get_token
    @@member_id = Setup.fetch_member_id
    Setup.write_config(@@token, @@member_id)
    puts "Done. Starting trello..."
    sleep 2
  end

  def self.reauthorize
    Setup.display_intro_text
    @@token = Setup.get_token
    @@member_id = Setup.fetch_member_id
    Setup.write_config(@@token, @@member_id)
    puts "Done. Starting trello..."
    sleep 2
  end

  def self.reset_screen
    NCurses.clear
    NCurses.erase
    NCurses.curs_set(1)
    NCurses.curs_set(0)
    @@windows.each { |w| w.resize }
    NCurses.refresh
  end

  module Colors
    extend self

    def cyan
      NCurses::ColorPair.new(1).init(NCurses::Color::CYAN, NCurses::Color::BLACK).attr
    end

    def blue
      NCurses::ColorPair.new(2).init(NCurses::Color::BLUE, NCurses::Color::BLACK).attr
    end

    def green
      NCurses::ColorPair.new(3).init(NCurses::Color::GREEN, NCurses::Color::BLACK).attr
    end

    def yellow
      NCurses::ColorPair.new(4).init(NCurses::Color::YELLOW, NCurses::Color::BLACK).attr
    end

    def red
      NCurses::ColorPair.new(5).init(NCurses::Color::RED, NCurses::Color::BLACK).attr
    end
  end

  module Setup
    extend self

    TEMPLATE_DIR = "#{CONFIG_DIR}/templates"

    def make_config_dir
      Dir.mkdir_p(CONFIG_DIR)
    end

    def make_templates
      Dir.mkdir_p(TEMPLATE_DIR)
      make_empty_template("comment.txt")
      make_attachment_template
      make_new_card_template
    end

    def display_intro_text
      puts
      puts "--| This app requires access to your trello account. |--"
      puts
      puts "I'll open up a web page requesting access. Once you accept, you will"
      puts "be presented with an API token. Copy that and use it in the next step."
      puts "Press ENTER to continue"
      gets
    end

    def get_token
      `open 'https://trello.com/1/authorize?expiration=never&scope=read,write,account&response_type=token&name=trello-cli&key=#{APP_KEY}'`
      print "Token: "
      gets
    end

    def fetch_member_id
      puts "Completing setup"
      json = API.get("members/me", "")
      json["id"].to_s
    end

    def write_config(token, member_id)
      secrets_file_path = "#{App::CONFIG_DIR}/secrets.json"

      if File.exists?(secrets_file_path)
        secrets = File.read(secrets_file_path)
        card_labels = JSON.parse(secrets)["cardLabels"]
        card_labels = Hash(String, String).from_json(card_labels.to_json)
      else
        card_labels = {} of String => String
      end

      secrets = JSON.build(indent: 2) do |json|
        json.object do
          json.field "token", token
          json.field "memberId", member_id
          json.field "cardLabels" do
            json.start_object
            card_labels.each do |k, v|
              json.field k, v
            end
            json.end_object
          end
        end
      end
      File.write(secrets_file_path, secrets)
    end

    def make_empty_template(template_name)
      File.write("#{TEMPLATE_DIR}/#{template_name}", "\n\n#{ignored_comments_declaration}")
    end

    def make_attachment_template
      content = <<-ATT
      {
        "name": "",
        "url": ""
      }

      #{Editor::COMMENT_STRING} CARD ATTACHMENT
      #{ignored_comments_declaration}
      ATT
      File.write("#{TEMPLATE_DIR}/attachment.json", content)
    end

    def make_new_card_template
      content = <<-CARD
      {
        "name": "",
        "description": ""
      }

      #{Editor::COMMENT_STRING} NEW CARD
      #{ignored_comments_declaration}
      CARD
      File.write("#{TEMPLATE_DIR}/new_card.json", content)
    end

    def ignored_comments_declaration
      "#{Editor::COMMENT_STRING} Lines that start with `#{Editor::COMMENT_STRING}` will be ignored."
    end
  end
end
