require "./api"

class LabelSelectWindow < ListSelectWindow
  property on_select : (String -> IO) | (String -> Nil) = ->(label_id : String) { }
  # @on_select : String -> IO) = ->(label_id : String) {}

  def initialize(@board_id : String, &block)
    super(x: NCurses.maxx / 4, y: NCurses.maxy / 4, width: NCurses.maxx / 2, height: NCurses.maxy / 2) do |win|
      win.title = "Available Labels"
      win.path = "boards/#{@board_id}/labels"
      App.add_window(win)
      App.activate_window(win)
      win.activate!
      yield win
    end
  end

  def activate!
    @active = true
    if !@path.empty?
      json = API.get(@path, @params)
      json.as_a.each do |j|
        @options << ListSelectOption.new(key: j.as_h["id"].to_s, value: j.as_h["name"].to_s)
      end
    end
  end

  def handle_select_previous
    super
    @win.close
    activate_parent!
    App.remove_window(self)
  end

  def handle_select_next(selected)
    @on_select.call(selected.key)
    handle_select_previous
  end
end
