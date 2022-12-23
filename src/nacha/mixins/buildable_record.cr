module BuildableRecord
  macro included
    property errors : Hash(String, Array(String)) do
      {} of String => Array(String)
    end
  end

  # Convert the record in to the record line
  abstract def build(io : IO) : IO

  # Every record is a single row. `File` uses
  # this to calculate the total number of rows
  # needed to build the file.
  def row_count : Int32
    1
  end

  def valid?
    errors.empty?
  end
end
