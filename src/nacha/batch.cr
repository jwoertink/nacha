module Nacha
  class Batch
    enum ServiceClassCode
      Mixed  = 200
      Credit = 220
      Debit  = 225
    end

    property header : Nacha::BatchHeader
    property entries : Array(Nacha::EntryDetail)
    property control : Nacha::BatchControl

    def initialize(@header, @entries, @control)
    end
  end
end
