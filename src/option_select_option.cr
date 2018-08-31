class OptionSelectOption
  getter key, value, json

  def initialize(@key : String, @value : String, @json : JSON::Any = JSON::Any.new("{}"))
  end
end
