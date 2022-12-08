module Nacha
  class EntryDetailAddenda
    include BuildableRecord

    TYPE_CODE    = 7
    ADDENDA_CODE = "05"

    def initialize(
      @entry_detail : EntryDetail,
      @payment_related_information : String? = nil,
      @sequence_number : Int32 = 1
    )
    end

    def build(io : IO) : IO
      io << TYPE_CODE.to_s
      io << ADDENDA_CODE
      io << @payment_related_information.to_s.ljust(80, ' ')
      io << @sequence_number.to_s.rjust(4, '0')
      io << @entry_detail.formatted_trace_number[8..-1]
      io
    end
  end
end
