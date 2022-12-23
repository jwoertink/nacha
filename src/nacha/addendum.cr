module Nacha
  class Addendum
    include BuildableRecord
    include ParsableRecord

    TYPE_CODE    = 7
    ADDENDA_CODE = "05"

    getter entry_detail_sequence_number : Int32
    getter payment_related_information : String?
    getter sequence_number : Int32

    def initialize(
      @entry_detail_sequence_number : Int32,
      @payment_related_information : String? = nil,
      @sequence_number : Int32 = 1
    )
    end

    def self.raise_parse_error(name : String, value : String)
      ParsableRecord.raise_parse_failed_error(name, value, "Addendum")
    end

    def self.parse(input : String) : self
      if input.bytesize == Nacha::File::RECORD_SIZE
        type_code = input[0].to_s
        type_code == TYPE_CODE.to_s || raise_parse_error("Type Code", type_code)

        addenda_type_code = input[1..2]
        addenda_type_code == ADDENDA_CODE || raise_parse_error("Addenda Type Code", addenda_type_code)

        payment_related_information = input[3..82]
        addenda_sequence_number = input[83..86]
        entry_detail_sequence_number = input[87..93]

        new(
          entry_detail_sequence_number: entry_detail_sequence_number.to_i,
          payment_related_information: payment_related_information.strip.presence,
          sequence_number: addenda_sequence_number.to_i,
        )
      else
        raise_parse_error("Record Length", input.bytesize.to_s)
      end
    end

    def build(io : IO) : IO
      io << TYPE_CODE.to_s
      io << ADDENDA_CODE
      io << @payment_related_information.to_s.ljust(80, ' ')
      io << @sequence_number.to_s.rjust(4, '0')
      io << @entry_detail_sequence_number.to_s.rjust(7, '0')
      io
    end
  end
end
