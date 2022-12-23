require "../spec_helper"

describe Nacha::FileHeader do
  describe "build" do
    it "formats the data correctly" do
      example = "101 012345678 8723161272212071417A094101Bank of Specialty      My Company Name                "
      example.bytesize.should eq(Nacha::File::RECORD_SIZE)

      current_time = Time.utc(2022, 12, 7, 14, 17, 0)

      io = IO::Memory.new
      file_header = Nacha::FileHeader.new(
        immediate_destination: "012345678",
        immediate_origin: "872316127",
        immediate_destination_name: "Bank of Specialty",
        immediate_origin_name: "My Company Name",
        file_creation_date: current_time,
        file_creation_time: current_time,
      )
      file_header.build(io)
      io.to_s.should eq(example)
    end
  end

  describe "parse" do
    it "parses the data correctly" do
      line = "101 021000021 3210001232209291648D094101WELLS FARGO BANK       ACME CORPORATION               "
      file_header = Nacha::FileHeader.parse(line)
      file_header.immediate_destination_name.should eq("WELLS FARGO BANK")
      file_header.immediate_origin_name.should eq("ACME CORPORATION")
      file_header.reference_code.should be_nil
    end

    context "errors" do
      it "raises when it's not a FileHeader" do
        line = "5200ACME CORPORATION                    1233211212WEBONLINEPYMT2209292209302731012000120000261"
        expect_raises(Nacha::ParserError, "Invalid Type Code '5' for File Header") do
          Nacha::FileHeader.parse(line)
        end
      end

      it "raises when it's the wrong length" do
        line = "101"
        expect_raises(Nacha::ParserError, "Invalid Record Length '3' for File Header") do
          Nacha::FileHeader.parse(line)
        end
      end
    end
  end
end
