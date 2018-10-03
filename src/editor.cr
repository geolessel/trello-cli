require "ncurses"
require "./app"

class Editor
  TEMP_FILE_PATH = "#{App::CONFIG_DIR}/trello.tmp"

  def self.run(contents : String = "", &block)
    clear_temp_file

    unless contents.empty?
      File.write(TEMP_FILE_PATH, contents)
    end

    Process.run(ENV["EDITOR"], args: {TEMP_FILE_PATH}, output: STDOUT, input: STDIN, error: STDERR, shell: true)

    App.reset_screen

    unless !File.exists?(TEMP_FILE_PATH) || File.empty?(TEMP_FILE_PATH)
      content = File.read(TEMP_FILE_PATH)
      yield content
    end
  end

  def self.clear_temp_file
    File.delete(TEMP_FILE_PATH) if File.exists?(TEMP_FILE_PATH)
  end
end
