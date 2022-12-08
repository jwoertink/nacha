module Nacha
  # This record contains the information necessary to post
  # a deposit to/withdrawal from an account, such as recipient’s name, account
  # number, dollar amount of the payment.
  class EntryDetail
    include BuildableRecord

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

    def initialize(
      @transaction_code : TransactionCode,        # Checking or Savings, Deposit or Withdraw
      @dfi_routing_number : String,               # Routing number
      @dfi_account_number : String,               # Account number
      @amount : Int32,                            # Amount to send in cents
      @individual_identification_number : String, # The individual's ID
      @individual_name : String,                  # Their name
      @discretionary_data : String? = nil,        # Optional extra 2 character data you want to add
      @addenda_included : Bool = false,
      @trace_number : Int32 = 1
    )
    end

    # First 8 of the routing number
    def receiving_dfi_identification : String
      @dfi_routing_number[0..7]
    end

    # Last digit of the routing number
    def check_digit : String
      @dfi_routing_number[8].to_s
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
      io << @trace_number.to_s.rjust(15, '0')
      io
    end
  end
end
