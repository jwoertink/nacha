module BuildableRecord
  # This turns the record in to it's data line
  abstract def build(io : IO) : IO

  def row_count : Int32
    1
  end
end
