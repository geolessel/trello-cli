module Wrap
  def wrap(text : String, width : Int32)
    chars = text.chars
    lines = [] of String
    until chars.empty?
      line = chars.shift(width)
      # preserve existing newlines
      if (newline_index = line.index { |c| c == '\n' })
        chars = line.last(line.size - newline_index - 1) + chars
        line = line[0..newline_index]
      end
      # line has whitespace to break on, so be gentle
      if line.any?(&.whitespace?)
        until chars.empty? || line.size == 1 || line.last.whitespace?
          chars.unshift(line.pop)
        end
      # line has no whitespace to break on, so be brutal
      elsif line.size > width
        chars.unshift(line.pop)
      end
      lines << line.join.strip
    end
    lines.join("\n")
  end
end
