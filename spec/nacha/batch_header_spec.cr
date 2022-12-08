require "../spec_helper"

describe Nacha::BatchHeader do
  describe "build" do
    it "formats the data correctly" do
      example = "5220My Company                          1234567890WEBPAY OUT   221207221207   1071000500000001"

      current_time = Time.utc(2022, 12, 7, 14, 17, 0)

      io = IO::Memory.new
      batch_header = Nacha::BatchHeader.new(
        service_class_code: :credit,
        company_name: "My Company",
        company_identification: "1234567890",
        standard_entry_class: :web,
        company_entry_description: "PAY OUT",
        effective_entry_date: current_time,
        company_descriptive_date: current_time,
        originating_financial_institution: "07100050",
      )
      batch_header.build(io)
      io.to_s.should eq(example)
      io.to_s.size.should eq(94)
    end
  end
end
