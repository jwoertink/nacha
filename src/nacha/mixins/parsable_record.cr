module ParsableRecord
  def self.parse(input : String) : self
    {% raise "Must define the parse method" %}
  end

  def self.raise_parse_failed_error(field : String, value : String, section : String)
    raise Nacha::ParserError.new("Invalid #{field} '#{value}' for #{section}")
  end
end
