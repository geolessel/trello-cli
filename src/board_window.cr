require "./option_select_window"
require "./lists_window"

class BoardsWindow < OptionSelectWindow
  def initialize
    super(x: 1, y: 1, height: 15, width: 25) do |win|
      win.path = "members/me/boards"
      win.params = "fields=name,starred,shortUrl"
      win.active = true
      win.title = "Boards"
    end
  end

  def activate_child!(option : OptionSelectOption)
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
        @options << OptionSelectOption.new(key: j.as_h["id"].to_s, value: j.as_h["starred"].to_s == "true" ? "★  #{j.as_h["name"]}" : j.as_h["name"].to_s)
      end
    end
  end

  def handle_select_previous
    # noop -- there is no previous
  end
end
