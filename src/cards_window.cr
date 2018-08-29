require "./details_window"
require "./card_detail"

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
