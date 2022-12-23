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

  describe "parse" do
    it "parses the data correctly" do
      line = "820000000100021000020000010000000000000000001233211212                         012000120000261"
      batch_control = Nacha::BatchControl.parse(line)
      batch_control.service_class_code.should eq(Nacha::Batch::ServiceClassCode::Mixed)
      batch_control.total_debit_amount.should eq(1000000i64)
      batch_control.total_credit_amount.should eq(0i64)
      batch_control.batch_number.should eq(261)
    end

    context "errors" do
      it "raises when it's not a BatchHeader" do
        line = "5200ACME CORPORATION                    1233211212WEBONLINEPYMT2209292209302731012000120000261"
        expect_raises(Nacha::ParserError, "Invalid Type Code '5' for Batch Control") do
          Nacha::BatchControl.parse(line)
        end
      end

      it "raises when it's the wrong length" do
        line = "8200"
        expect_raises(Nacha::ParserError, "Invalid Record Length '4' for Batch Control") do
          Nacha::BatchControl.parse(line)
        end
      end
    end
  end
end
