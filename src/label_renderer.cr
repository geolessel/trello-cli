require "./app"

class LabelRenderer
  def self.render(win, labels)
    labels.each do |label|
      if App.card_labels[label]?
        win.addstr(App.card_labels[label])
      end
    end
  end
end
