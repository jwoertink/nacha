module Nacha
  class Batch
    property header : Nacha::BatchHeader
    property entries : Array(Nacha::EntryDetail)
    property control : Nacha::BatchControl

    def initialize(@header, @entries, @control)
    end
  end
end
