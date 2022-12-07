require "../spec_helper"

describe Nacha::FileHeader do
  describe "build" do
    it "formats the data correctly" do
      example = "101 021406766 8723856712212071417A094101Bank of Specialty      JSTV Enterprises               "

      current_time = Time.utc(2022, 12, 7, 14, 17, 0)

      io = IO::Memory.new
      file_header = Nacha::FileHeader.new(
        immediate_destination: "021406766",
        immediate_origin: "872385671",
        immediate_destination_name: "Bank of Specialty",
        immediate_origin_name: "JSTV Enterprises",
        file_creation_date: current_time,
        file_creation_time: current_time,
      )
      file_header.build(io)
      io.to_s.should eq(example)
    end
  end
end
