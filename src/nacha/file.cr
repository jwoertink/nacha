module Nacha
  class File
    property header : Nacha::FileHeader
    property batches : Array(Nacha::Batch)
    property control : Nacha::FileControl

    def initialize(@header, @batches, @control)
    end

    def generate
    end
  end
end
