module Nacha
  class Batch
    include BuildableRecord

    enum ServiceClassCode
      Mixed  = 200
      Credit = 220
      Debit  = 225
    end

    getter header : Nacha::BatchHeader
    getter entries : Array(Nacha::EntryDetail)
    getter control : Nacha::BatchControl

    def initialize(@header : BatchHeader, @entries : Array(EntryDetail))
      @control = Nacha::BatchControl.new(
        service_class_code: @header.service_class_code,
        entry_addenda_count: @entries.size,
        entry_hash: entry_hash,
        total_debit_amount: total_debit_amount,
        total_credit_amount: total_credit_amount,
        company_identification: @header.company_identification,
        originating_dfi_identification: @header.originating_dfi_identification,
        batch_number: @header.batch_number
      )
    end

    def build(io : IO) : IO
      header.build(io)
      io << "\n"
      entries.each do |entry|
        entry.build(io)
        io << "\n"
      end
      control.build(io)
      io
    end

    def row_count : Int32
      header.row_count + entries.sum(0, &.row_count) + control.row_count
    end

    def entry_hash : String
      total = @entries.sum(0, &.receiving_dfi_identification.to_i).to_s
      if total.bytesize > 10
        total[-10..-1]
      else
        total.rjust(10, '0')
      end
    end

    def total_debit_amount : Int64
      @entries.select(&.debit?).sum(0, &.amount).to_i64
    end

    def total_credit_amount : Int64
      @entries.select(&.credit?).sum(0, &.amount).to_i64
    end
  end
end
