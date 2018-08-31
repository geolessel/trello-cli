require "./option_select_window"
require "./card_detail"

class CardsWindow < OptionSelectWindow
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
    @params = "fields=name,shortUrl&members=true"
  end

  def render_row(option)
    member_ids = option.json.as_h["members"].as_a.map { |m| m["id"].to_s }
    if member_ids.includes?(App::MEMBER_ID)
      win.attron(App::Colors.yellow)
      super
      win.attroff(App::Colors.yellow)
    else
      super
    end
  end

  def handle_select_next(selected)
    card = CardDetail.new(id: selected.key, name: selected.value)

    details = DetailsWindow.new(card: card)
    details.link_parent(self)
    details.activate!
    @active = false
    @visible = false
    @win.erase
    @win.refresh
  end
end
