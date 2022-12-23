require "../spec_helper"

describe Nacha::FileControl do
  describe "build" do
    it "formats the data correctly" do
      example = "9000001000005000000011234567890000000000000000000050099                                       "
      example.bytesize.should eq(Nacha::File::RECORD_SIZE)

      io = IO::Memory.new
      file_control = Nacha::FileControl.new(
        batch_count: 1,
        block_count: 5,
        entry_count: 1,
        entry_hash: 1234567890,
        total_debit_amount: 0,
        total_credit_amount: 50099,
      )
      file_control.build(io)
      io.to_s.should eq(example)
    end
  end

  describe "parse" do
    it "parses the data correctly" do
      line = "9000001000001000000010002100002000001000000000000000000                                       "
      file_control = Nacha::FileControl.parse(line)
      file_control.batch_count.should eq(1)
      file_control.block_count.should eq(1)
      file_control.entry_count.should eq(1)
      file_control.entry_hash.should eq(2100002i64)
      file_control.total_debit_amount.should eq(1000000i64) # $10,000.00
      file_control.total_credit_amount.should eq(0i64)
    end

    context "errors" do
      it "raises when it's not a FileHeader" do
        line = "5200ACME CORPORATION                    1233211212WEBONLINEPYMT2209292209302731012000120000261"
        expect_raises(Nacha::ParserError, "Invalid Type Code '5' for File Control") do
          Nacha::FileControl.parse(line)
        end
      end

      it "raises when it's the wrong length" do
        line = "900"
        expect_raises(Nacha::ParserError, "Invalid Record Length '3' for File Control") do
          Nacha::FileControl.parse(line)
        end
      end
    end
  end
end
