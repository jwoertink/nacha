require "../spec_helper"

describe Nacha::Batch do
  describe "build" do
    it "builds a full batch record" do
      example = <<-NACHA
      5220My Company                          1234567890WEBPAY OUT   221207221207   1071000500000001
      62210264791931945123488995   0000062432418            Billy Bonka             0000000000000001
      622318092165493805838128300  0000035249419            Milly Monka             0000000000000002
      822000000200420740070000000000000000000976811234567890                         071000500000001
      NACHA

      # 4 rows plus 3 linebreaks
      example_size = Nacha::File::RECORD_SIZE * 4 + 3
      example.bytesize.should eq(example_size)

      current_time = Time.utc(2022, 12, 7, 14, 17, 0)

      batch_header = Nacha::BatchHeader.new(
        service_class_code: :credit,
        company_name: "My Company",
        company_identification: "1234567890",
        standard_entry_class: :web,
        company_entry_description: "PAY OUT",
        effective_entry_date: current_time,
        company_descriptive_date: current_time,
        originating_dfi_identification: "07100050",
        originator_status_code: '1',
      )
      entry1 = Nacha::EntryDetail.new(
        transaction_code: :checking_credit,
        dfi_routing_number: "102647919",
        dfi_account_number: "31945123488995",
        amount: 62432, # $624.32
        individual_identification_number: "418",
        individual_name: "Billy Bonka",
        trace_number: "1"
      )
      entry2 = Nacha::EntryDetail.new(
        transaction_code: :checking_credit,
        dfi_routing_number: "318092165",
        dfi_account_number: "493805838128300",
        amount: 35249, # $352.49
        individual_identification_number: "419",
        individual_name: "Milly Monka",
        trace_number: "2"
      )
      batch = Nacha::Batch.new(
        header: batch_header,
        entries: [entry1, entry2] of Nacha::EntryDetail
      )

      io = IO::Memory.new
      batch.build(io)
      io.to_s.should eq(example)
    end
  end
end
