module Nacha
  # This record contains the information necessary to post
  # a deposit to/withdrawal from an account, such as recipient’s name, account
  # number, dollar amount of the payment.
  class EntryDetail
    include BuildableRecord
    include ParsableRecord

    TYPE_CODE = 6

    enum TransactionCode
      CheckingCredit        = 22
      CheckingCreditPrenote = 23
      CheckingDebit         = 27
      CheckingDebitPrenote  = 28
      SavingsCredit         = 32
      SavingsCreditPrenote  = 33
      SavingsDebit          = 37
      SavingsDebitPrenote   = 38
    end

    getter transaction_code : TransactionCode        # Checking or Savings, Deposit or Withdraw
    getter dfi_routing_number : String               # Routing number
    getter dfi_account_number : String               # Account number
    getter amount : Int32                            # Amount to send in cents
    getter individual_identification_number : String # The individual's ID
    getter individual_name : String                  # Their name
    getter discretionary_data : String?              # Optional extra 2 character data you want to add
    getter addenda_included : Bool
    getter trace_number : Int64

    def initialize(
      @transaction_code : TransactionCode,
      @dfi_routing_number : String,
      @dfi_account_number : String,
      @amount : Int32,
      @individual_identification_number : String,
      @individual_name : String,
      @discretionary_data : String? = nil,
      @addenda_included : Bool = false,
      @trace_number : Int64 = 1i64
    )
    end

    def self.raise_parse_error(name : String, value : String)
      ParsableRecord.raise_parse_failed_error(name, value, "Entry Detail")
    end

    def self.parse(input : String) : self
      if input.bytesize == Nacha::File::RECORD_SIZE
        type_code = input[0].to_s
        type_code == TYPE_CODE.to_s || raise_parse_error("Type Code", type_code)

        transaction_code = input[1..2]
        transaction_code.match(/\d+/) || raise_parse_error("Transaction Code", transaction_code)

        receiving_dfi_identification = input[3..10]

        check_digit = input[11].to_s
        check_digit.match(/\d/) || raise_parse_error("Check Digit", check_digit)

        dfi_account_number = input[12..28]

        amount = input[29..38]
        amount.match(/\d+/) || raise_parse_error("Amount", amount)

        individual_identification_number = input[39..53]
        individual_name = input[54..75]
        discretionary_data = input[76..77]
        addenda_record_indicator = input[78]
        trace_number = input[79..93]

        new(
          transaction_code: TransactionCode.from_value(transaction_code.to_i),
          dfi_routing_number: receiving_dfi_identification + check_digit,
          dfi_account_number: dfi_account_number.strip,
          amount: amount.to_i,
          individual_identification_number: individual_identification_number,
          individual_name: individual_name.strip,
          discretionary_data: discretionary_data.strip.presence,
          addenda_included: addenda_record_indicator == '1',
          trace_number: trace_number.to_i64,
        )
      else
        raise_parse_error("Record Length", input.bytesize.to_s)
      end
    end

    def debit? : Bool
      @transaction_code.checking_debit? || @transaction_code.savings_debit?
    end

    def credit? : Bool
      @transaction_code.checking_credit? || @transaction_code.savings_credit?
    end

    # First 8 of the routing number
    def receiving_dfi_identification : String
      @dfi_routing_number[0..7]
    end

    # Last digit of the routing number
    def check_digit : String
      @dfi_routing_number[8].to_s
    end

    def formatted_trace_number : String
      @trace_number.to_s.rjust(15, '0')
    end

    def build(io : IO) : IO
      io << TYPE_CODE.to_s
      io << @transaction_code.value.to_s
      io << receiving_dfi_identification
      io << check_digit
      io << @dfi_account_number[0..16].ljust(17, ' ')
      io << @amount.to_s.rjust(10, '0')
      io << @individual_identification_number.rjust(15, ' ')
      io << @individual_name.rjust(22, ' ')
      io << @discretionary_data.to_s.ljust(2, ' ')
      io << (@addenda_included ? "1" : "0")
      io << formatted_trace_number
      io
    end
  end
end
