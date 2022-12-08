module Nacha
  # This record indicates the effective entry date (the
  # date you request the deposits/debits to be settled). In addition, this record
  # identifies your company and provides an entry description for the credit and
  # debits in this batch.
  class BatchHeader
    include BuildableRecord

    TYPE_CODE = 5

    enum ServiceClassCode
      Mixed = 200
      Credit = 220
      Debit = 225
    end

    enum StandardEntryClass
      PPD # Prearranged Payments and Deposit entries
      CCD # Cash Concentration and Disbursement entries
      CTX # Corporate Trade Exchange entries
      TEL # Telephone initiated entries
      WEB # Authorization received via the Internet
    end

    def initialize(
      @service_class_code : ServiceClassCode, # Credit, Debit, Mixed
      @company_name : String, # Same as immediate_origin_name in the FileHeader
      @company_identification : String, # This should be the immediate_origin from the FileHeader or a custom designation
      @standard_entry_class : StandardEntryClass, # Type reason for the money transfer
      @company_entry_description : String, # Description of the transaction to be printed on the receivers' bank statement
      @effective_entry_date : Time, # The date to post the transaction
      @originating_financial_institution : String, # Same as immediate_destination in FileHeader
      @company_discretionary_data : String? = nil, # For your custom accounting purposes
      @company_descriptive_date : Time? = nil, # The date to print on the receivers' bank statement
      @originator_status_code : Char = '1', # just because
      @batch_number : Int32 = 1 # Increment this for each batch
    )
    end

    def build(io : IO) : IO
      io << TYPE_CODE.to_s
      io << @service_class_code.value.to_s
      io << @company_name[0..15].ljust(16, ' ')
      io << @company_discretionary_data.to_s.ljust(20, ' ')
      io << @company_identification.rjust(10, ' ')
      io << @standard_entry_class.to_s
      io << @company_entry_description.ljust(10, ' ')
      io << @company_descriptive_date.try(&.to_s("%y%m%d")).to_s.ljust(6, ' ')
      io << @effective_entry_date.to_s("%y%m%d")
      io << "   "
      io << @originator_status_code.to_s
      io << @originating_financial_institution.to_s.rjust(8, ' ')
      io << @batch_number.to_s.rjust(7, '0')
      io
    end
  end
end
