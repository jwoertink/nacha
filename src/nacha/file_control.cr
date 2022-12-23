module Nacha
  # This record provides a final check on the data
  # submitted. It contains block and batch count(s)
  # and totals for each type of entry
  class FileControl
    include BuildableRecord
    include ParsableRecord

    TYPE_CODE      = 9
    RESERVED_SPACE = " " * 39

    getter batch_count : Int32         # Total number of BatchHeader records
    getter block_count : Int32         # A "block" is 10 rows. The number of blocks in the file
    getter entry_count : Int32         # Total number of EntryDetail and EntryDetailAddenda records
    getter entry_hash : Int64          # Sum of all BatchControl entry_hashes
    getter total_debit_amount : Int64  # Sum of all BatchControl total_debit_amount
    getter total_credit_amount : Int64 # Sum of all BatchControl total_credit_amount

    def initialize(
      @batch_count : Int32,
      @block_count : Int32,
      @entry_count : Int32,
      @entry_hash : Int64,
      @total_debit_amount : Int64,
      @total_credit_amount : Int64
    )
    end

    def self.raise_parse_error(name : String, value : String)
      ParsableRecord.raise_parse_failed_error(name, value, "File Control")
    end

    def self.parse(input : String) : self
      if input.bytesize == Nacha::File::RECORD_SIZE
        type_code = input[0].to_s
        type_code == TYPE_CODE.to_s || raise_parse_error("Type Code", type_code)

        batch_count = input[1..6]
        batch_count.match(/\d+/) || raise_parse_error("Batch Count", batch_count)

        block_count = input[7..12]
        block_count.match(/\d+/) || raise_parse_error("Block Count", block_count)

        entry_count = input[13..20]
        entry_count.match(/\d+/) || raise_parse_error("Entry/Addenda Count", entry_count)

        entry_hash = input[21..30]
        entry_hash.match(/\d+/) || raise_parse_error("Entry Hash", entry_hash)

        total_debit_amount = input[31..42]
        total_debit_amount.match(/\d+/) || raise_parse_error("Total Debit Amount", total_debit_amount)

        total_credit_amount = input[43..54]
        total_credit_amount.match(/\d+/) || raise_parse_error("Total Credit Amount", total_credit_amount)

        reserved = input[55..93]
        reserved == RESERVED_SPACE || raise_parse_error("Reserved Space", reserved)

        new(
          batch_count: batch_count.to_i,
          block_count: block_count.to_i,
          entry_count: entry_count.to_i,
          entry_hash: entry_hash.to_i64,
          total_debit_amount: total_debit_amount.to_i64,
          total_credit_amount: total_credit_amount.to_i64,
        )
      else
        raise_parse_error("Record Length", input.bytesize.to_s)
      end
    end

    def build(io : IO) : IO
      io << TYPE_CODE.to_s
      io << @batch_count.to_s.rjust(6, '0')
      io << @block_count.to_s.rjust(6, '0')
      io << @entry_count.to_s.rjust(8, '0')
      io << @entry_hash.to_s.rjust(10, '0')
      io << @total_debit_amount.to_s.rjust(12, '0')
      io << @total_credit_amount.to_s.rjust(12, '0')
      io << RESERVED_SPACE
      io
    end
  end
end
