module Wrap
  def wrap(text : String, width : Int32)
    chars = text.chars
    lines = [] of String
    until chars.empty?
      line = chars.shift(width + 1)
      if line.any?(&.whitespace?)
        until chars.empty? || line.size == 1 || line.last.whitespace?
          chars.unshift(line.pop)
        end
      elsif line.size > width
        chars.unshift(line.pop)
      end
      lines << line.join.strip
    end
    lines.join("\n")
  end
end
