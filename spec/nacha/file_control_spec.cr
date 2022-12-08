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
end
