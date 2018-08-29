require "./list_select_option"
require "./cards_window"

class ListsWindow < ListSelectWindow
  property board_id : String = ""

  def initialize
    super(x: 1, y: 17, height: 15, width: 25) do |win|
      win.title = "Lists"
    end
  end

  def set_board_id(id : String)
    @path = "boards/#{id}/lists"
    @params = "fields=name,shortUrl"
  end

  def activate_child!(option : ListSelectOption)
    child = @child
    if child
      @active = false
      child.set_list_id(option.key) if child.is_a? CardsWindow
      child.activate!
    end
  end
end
