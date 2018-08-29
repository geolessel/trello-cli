require "./option_select_window"

class AttachmentSelectWindow < OptionSelectWindow
  property on_select : (String -> IO) | (String -> Nil) = ->(list_id : String) {}

  def initialize(@card_id : String, &block)
    super(x: NCurses.maxx / 4, y: NCurses.maxy / 4, height: NCurses.maxy / 2, width: NCurses.maxx / 2) do |win|
      win.title = "Attachments"
      win.path = "cards/#{@card_id}/attachments"
      App.add_window(win)
      App.activate_window(win)
      win.activate!
      yield win
    end
  end

  def fetch
    if !@path.empty?
      json = API.get(@path, @params)
      json.as_a.each do |j|
        @options << OptionSelectOption.new(key: j.as_h["url"].to_s, value: j.as_h["name"].to_s)
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
