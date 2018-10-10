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
    @list_id = id
    @path = "lists/#{id}/cards"
    @params = "fields=name,shortUrl&members=true"
  end

  def render_row(option)
    member_ids = option.json.as_h["members"].as_a.map { |m| m["id"].to_s }
    notification = App.notifications[option.json.as_h["id"]]?
    if member_ids.includes?(App.member_id)
      win.attron(App::Colors.yellow)
      Notification.render(win) if notification
      super
      win.attroff(App::Colors.yellow)
    else
      Notification.render(win) if notification
      super
    end
  end

  def handle_select_next(selected)
    card = CardDetail.new(id: selected.key, name: selected.value)
    Notification.mark_read_for_card(card)

    details = DetailsWindow.new(card: card)
    details.link_parent(self)
    details.activate!
    @active = false
    @visible = false
    @win.erase
    @win.refresh
  end

  def add_helps(win)
    win.add_help(key: "c", description: "Create a new card on this list")
    super
  end

  def handle_key(key)
    case key
    when 'c'
      Editor.run(template: "new_card.json") do |card_json|
        card = JSON.parse(card_json)
        API.post("/cards", params: "idList=#{@list_id}", form: "name=#{card["name"]}&desc=#{card["description"]}")
        fetch
      end
    else
      super
    end
  end
end
