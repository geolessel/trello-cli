module Wrap
  def wrap(text, width)
    chars = text.chars
    lines = [] of String
    until chars.empty?
      line = chars.shift(width + 1)
      if line.any? { |c| c.whitespace? }
        until chars.empty? || line.size == 1 || line.last.whitespace?
          chars.unshift(line.pop)
        end
      elsif line.size > width
        chars.unshift(line.pop)
      end
      lines << line.join.rstrip
    end
    lines.join("\n")
  end
end
