require "ncurses"
require "./app"

class Editor
  TEMP_FILE_PATH = "#{App::CONFIG_DIR}/trello.tmp"
  TEMPLATES_PATH = "#{App::CONFIG_DIR}/templates"
  COMMENT_STRING = "//"

  def self.run(template : (String | Nil) = nil, &block)
    clear_temp_file

    if template
      copy_template_file(template)
    end

    Process.run(ENV["EDITOR"], args: {TEMP_FILE_PATH}, output: STDOUT, input: STDIN, error: STDERR, shell: true)

    App.reset_screen

    unless !File.exists?(TEMP_FILE_PATH) || File.empty?(TEMP_FILE_PATH)
      content = File.read(TEMP_FILE_PATH).chomp
      content = strip_comments(content)
      yield content
    end
  end

  def self.clear_temp_file
    File.delete(TEMP_FILE_PATH) if File.exists?(TEMP_FILE_PATH)
  end

  def self.copy_template_file(template_file)
    full_path = "#{TEMPLATES_PATH}/#{template_file}"
    unless !File.exists?(full_path) || File.empty?(full_path)
      content = File.read(full_path)
      File.write(TEMP_FILE_PATH, content)
    end
  end

  def self.strip_comments(content)
    content.split("\n").reject { |l| l.starts_with?(COMMENT_STRING) }.join("\n").chomp
  end
end
