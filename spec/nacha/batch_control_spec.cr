require "../spec_helper"

describe Nacha::BatchControl do
  describe "build" do
    it "formats the data correctly" do
      example = "822000000212345678900000000000000000001243911234567890                         071000500000001"
      example.bytesize.should eq(Nacha::File::RECORD_SIZE)

      io = IO::Memory.new
      batch_control = Nacha::BatchControl.new(
        service_class_code: :credit,
        entry_addenda_count: 2,
        entry_hash: "1234567890",
        total_debit_amount: 0,
        total_credit_amount: 124391,
        company_identification: "1234567890",
        originating_dfi_identification: "07100050",
        batch_number: 1,
      )
      batch_control.build(io)
      io.to_s.should eq(example)
    end
  end
end
