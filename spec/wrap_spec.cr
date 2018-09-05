require "./spec_helper"

include Wrap

describe Wrap do
  it "wraps on spaces" do
    result = wrap("Lorem ipsum dolor sit amet", 15)
    result.should eq("Lorem ipsum\ndolor sit amet")
  end

  it "does not try to split a word that is correct width" do
    result = wrap("Loremipsumdolor", 15)
    result.should eq("Loremipsumdolor")
    result = wrap("Loremipsumdolor sit amet", 15)
    result.should eq("Loremipsumdolor\nsit amet")
  end

  it "wraps a word that is too long without adding a blank line" do
    result = wrap("Loremipsumdolor sit amet", 13)
    result.should eq("Loremipsumdol\nor sit amet")
  end

  it "preserves existing newlines" do
    result = wrap("Lorem ipsum dolor\n\nsit amet", 13)
    result.should eq("Lorem ipsum\ndolor\n\nsit amet")
  end
end
