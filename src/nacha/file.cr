module Nacha
  class File
    RECORD_SIZE     = 94  # The number of bytes per record row
    BLOCKING_FACTOR = 10  # All files must have line numbers divisible by 10
    FORMAT_CODE     = '1' # Placeholder for future other formats

    property header : Nacha::FileHeader
    property batches : Array(Nacha::Batch)
    property control : Nacha::FileControl

    def initialize(@header, @batches, @control)
    end

    def generate
    end
  end
end
