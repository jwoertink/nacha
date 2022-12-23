module Nacha
  # This record indicates the effective entry date (the
  # date you request the deposits/debits to be settled). In addition, this record
  # identifies your company and provides an entry description for the credit and
  # debits in this batch.
  class BatchHeader
    include BuildableRecord
    include ParsableRecord

    TYPE_CODE = 5

    enum StandardEntryClass
      PPD # Prearranged Payments and Deposit entries
      CCD # Cash Concentration and Disbursement entries
      CTX # Corporate Trade Exchange entries
      TEL # Telephone initiated entries
      WEB # Authorization received via the Internet
    end

    getter service_class_code : Batch::ServiceClassCode # Credit, Debit, Mixed
    getter company_name : String                        # Same as immediate_origin_name in the FileHeader
    getter company_identification : String              # This should be the immediate_origin from the FileHeader or a custom designation
    getter standard_entry_class : StandardEntryClass    # Type reason for the money transfer
    getter company_entry_description : String           # Description of the transaction to be printed on the receivers' bank statement
    getter effective_entry_date : Time                  # The date to post the transaction
    getter originating_dfi_identification : String      # Same as immediate_destination in FileHeader
    getter originator_status_code : Char                # The ODFI initiating the entry.
    getter company_discretionary_data : String?         # For your custom accounting purposes
    getter company_descriptive_date : Time?             # The date to print on the receivers' bank statement
    getter settlement_date : Int32?                     # A 3 digit Julian date. This is inserted by the ACH processor
    getter batch_number : Int32                         # Increment this for each batch

    def initialize(
      @service_class_code : Batch::ServiceClassCode,
      @company_name : String,
      @company_identification : String,
      @standard_entry_class : StandardEntryClass,
      @company_entry_description : String,
      @effective_entry_date : Time,
      @originating_dfi_identification : String,
      @originator_status_code : Char,
      @company_discretionary_data : String? = nil,
      @company_descriptive_date : Time? = nil,
      @settlement_date : Int32? = nil,
      @batch_number : Int32 = 1
    )
    end

    def self.raise_parse_error(name : String, value : String)
      ParsableRecord.raise_parse_failed_error(name, value, "Batch Header")
    end

    def self.parse(input : String) : self
      if input.bytesize == Nacha::File::RECORD_SIZE
        type_code = input[0].to_s
        type_code == TYPE_CODE.to_s || raise_parse_error("Type Code", type_code)

        service_class_code = input[1..3]
        service_class_code.match(/\d+/) || raise_parse_error("Service Class Code", service_class_code)

        company_name = input[4..19]
        company_discretionary_data = input[20..39]
        company_identification = input[40..49]
        standard_entry_class = input[50..52]
        company_entry_description = input[53..62]
        company_descriptive_date = input[63..68]

        effective_entry_date = input[69..74]
        effective_entry_date.match(/\d{6}/) || raise_parse_error("Effective Entry Date", effective_entry_date)

        settlement_date = input[75..77]
        settlement_date.match(/(\s{3}|\d{3})/) || raise_parse_error("Settlement Date", settlement_date)

        originator_status_code = input[78]
        originating_dfi_identification = input[79..86]
        batch_number = input[87..93]
        batch_number.match(/\d+/) || raise_parse_error("Batch Number", batch_number)

        new(
          service_class_code: Batch::ServiceClassCode.from_value(service_class_code.to_i),
          company_name: company_name,
          company_identification: company_identification,
          standard_entry_class: StandardEntryClass.parse(standard_entry_class),
          company_entry_description: company_entry_description,
          effective_entry_date: Time.parse_utc(effective_entry_date, "%y%m%d"),
          originating_dfi_identification: originating_dfi_identification,
          originator_status_code: originator_status_code,
          company_discretionary_data: company_discretionary_data.strip.presence,
          company_descriptive_date: company_descriptive_date.strip.presence.try { |val| Time.parse_utc(val, "%y%m%d") },
          batch_number: batch_number.to_i,
        )
      else
        raise_parse_error("Record Length", input.bytesize.to_s)
      end
    end

    def build(io : IO) : IO
      run_input_validations!
      io << TYPE_CODE.to_s
      io << service_class_code.value.to_s
      io << company_name[0..15].ljust(16, ' ')
      io << company_discretionary_data.to_s.ljust(20, ' ')
      io << company_identification.rjust(10, ' ')
      io << standard_entry_class.to_s
      io << company_entry_description.ljust(10, ' ')
      io << company_descriptive_date.try(&.to_s("%y%m%d")).to_s.ljust(6, ' ')
      io << effective_entry_date.to_s("%y%m%d")
      io << settlement_date.to_s.ljust(3, ' ')
      io << originator_status_code.to_s
      io << originating_dfi_identification.to_s.rjust(8, ' ')
      io << batch_number.to_s.rjust(7, '0')
      io
    end

    private def run_input_validations!
      if company_name.to_s.size > 16
        errors["company_name"] = ["is too long"]
      end

      if company_discretionary_data.to_s.size > 20
        errors["company_discretionary_data"] = ["is too long"]
      end

      if company_identification.to_s.size > 10
        errors["company_identification"] = ["is too long"]
      end

      if company_entry_description.to_s.size > 10
        errors["company_entry_description"] = ["is too long"]
      end

      if originating_dfi_identification.to_s.size > 8
        errors["originating_dfi_identification"] = ["is too long"]
      end

      if !valid?
        raise Nacha::BuildError.new("Could not build Batch Header")
      end
    end
  end
end
