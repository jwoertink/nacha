module Nacha
  # This record appears at the end of each batch and
  # contains totals for the batch. The data in this
  # should be calculated in the `Batch`
  class BatchControl
    include BuildableRecord
    include ParsableRecord

    TYPE_CODE      = 8
    RESERVED_SPACE = " " * 6

    getter service_class_code : Batch::ServiceClassCode # Credit, Debit, Mixed
    getter entry_addenda_count : Int32                  # Total number of entries in the batch
    getter entry_hash : String                          # Add all `receiving_dfi_identification` from all entries, then return last 10 digits
    getter total_debit_amount : Int64
    getter total_credit_amount : Int64
    getter company_identification : String
    getter originating_dfi_identification : String
    getter batch_number : Int32 # Same as the BatchHeader#batch_number
    getter message_authorization_code : Int32?

    def initialize(
      @service_class_code : Batch::ServiceClassCode,
      @entry_addenda_count : Int32,
      @entry_hash : String,
      @total_debit_amount : Int64,
      @total_credit_amount : Int64,
      @company_identification : String,
      @originating_dfi_identification : String,
      @batch_number : Int32,
      @message_authorization_code : Int32? = nil
    )
    end

    def self.raise_parse_error(name : String, value : String)
      ParsableRecord.raise_parse_failed_error(name, value, "Batch Control")
    end

    def self.parse(input : String) : self
      if input.bytesize == Nacha::File::RECORD_SIZE
        type_code = input[0].to_s
        type_code == TYPE_CODE.to_s || raise_parse_error("Type Code", type_code)

        service_class_code = input[1..3]
        service_class_code.match(/\d{3}/) || raise_parse_error("Service Class Code", service_class_code)

        entry_addenda_count = input[4..9]
        entry_addenda_count.match(/\d+/) || raise_parse_error("Entry Addenda Count", entry_addenda_count)

        entry_hash = input[10..19]
        entry_hash.match(/\d+/) || raise_parse_error("Entry Hash", entry_hash)

        total_debit_amount = input[20..31]
        total_debit_amount.match(/\d+/) || raise_parse_error("Total Debit Amount", total_debit_amount)

        total_credit_amount = input[32..43]
        total_credit_amount.match(/\d+/) || raise_parse_error("Total Credit Amount", total_credit_amount)

        company_identification = input[44..53]
        message_authorization_code = input[54..72]
        reserved_space = input[73..78]
        reserved_space == RESERVED_SPACE || raise_parse_error("Reserved Space", reserved_space)

        originating_dfi_identification = input[79..86]
        batch_number = input[87..93]

        new(
          service_class_code: Nacha::Batch::ServiceClassCode.from_value(service_class_code.to_i),
          entry_addenda_count: entry_addenda_count.to_i,
          entry_hash: entry_hash,
          total_debit_amount: total_debit_amount.to_i64,
          total_credit_amount: total_credit_amount.to_i64,
          company_identification: company_identification,
          originating_dfi_identification: originating_dfi_identification,
          batch_number: batch_number.to_i,
          message_authorization_code: message_authorization_code.strip.presence.try(&.to_i),
        )
      else
        raise_parse_error("Record Length", input.bytesize.to_s)
      end
    end

    def build(io : IO) : IO
      run_input_validations!
      io << TYPE_CODE.to_s
      io << service_class_code.value.to_s
      io << entry_addenda_count.to_s.rjust(6, '0')
      io << entry_hash
      io << total_debit_amount.to_s.rjust(12, '0')
      io << total_credit_amount.to_s.rjust(12, '0')
      io << company_identification.rjust(10, ' ')
      io << message_authorization_code.to_s.ljust(19, ' ')
      io << RESERVED_SPACE
      io << originating_dfi_identification.to_s.rjust(8, ' ')
      io << batch_number.to_s.rjust(7, '0')
      io
    end

    private def run_input_validations!
      if company_identification.to_s.size > 10
        errors["company_identification"] = ["is too long"]
      end

      if entry_hash.to_s.size > 10
        errors["entry_hash"] = ["is too long"]
      end

      if originating_dfi_identification.to_s.size > 8
        errors["originating_dfi_identification"] = ["is too long"]
      end

      if !valid?
        raise Nacha::BuildError.new("Could not build Batch Control")
      end
    end
  end
end
