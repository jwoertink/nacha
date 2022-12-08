module Nacha
  # This record provides a final check on the data
  # submitted. It contains block and batch count(s)
  # and totals for each type of entry
  class FileControl
    include BuildableRecord

    TYPE_CODE      = 9
    RESERVED_SPACE = " " * 39

    def initialize(
      @batch_count : Int32,        # Total number of BatchHeader records
      @block_count : Int32,        # Total number of rows including this one
      @entry_count : Int32,        # Total number of EntryDetail and EntryDetailAddenda records
      @entry_hash : Int64,         # Sum of all BatchControl entry_hashes
      @total_debit_amount : Int64, # Sum of all BatchControl total_debit_amount
      @total_credit_amount : Int64 # Sum of all BatchControl total_credit_amount
    )
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
