module Nacha
  # This record appears at the end of each batch and
  # contains totals for the batch. The data in this
  # should be calculated in the `Batch`
  class BatchControl
    include BuildableRecord

    TYPE_CODE      = 8
    RESERVED_SPACE = " " * 6

    def initialize(
      @service_class_code : Batch::ServiceClassCode, # Credit, Debit, Mixed
      @entry_addenda_count : Int32,                  # Total number of entries in the batch
      @entry_hash : Int64,                           # Add all `receiving_dfi_identification` from all entries, then return last 10 digits
      @total_debit_amount : Int64,
      @total_credit_amount : Int64,
      @company_identification : String,
      @originating_dfi_identification : String,
      @batch_number : Int32, # Same as the BatchHeader#batch_number
      @message_authorization_code : Int32? = nil
    )
    end

    def build(io : IO) : IO
      io << TYPE_CODE.to_s
      io << @service_class_code.value.to_s
      io << @entry_addenda_count.to_s.rjust(6, '0')
      io << @entry_hash.to_s
      io << @total_debit_amount.to_s.rjust(12, '0')
      io << @total_credit_amount.to_s.rjust(12, '0')
      io << @company_identification.rjust(10, ' ')
      io << @message_authorization_code.to_s.ljust(19, ' ')
      io << RESERVED_SPACE
      io << @originating_dfi_identification.to_s.rjust(8, ' ')
      io << @batch_number.to_s.rjust(7, '0')
      io
    end
  end
end
