module Nacha
  class Parser
    # TODO: Figure out a cleaner way to handle this.
    # I'm using this to group batches and entires together
    # so when I build the objects, they're all properly related
    private property raw_data : Hash(String, String | Array(Hash(String, String | Array(String)))) do
      {} of String => String | Array(Hash(String, String | Array(String)))
    end

    # `input` should be the entire ACH file.
    def parse(input : String) : Nacha::File
      data = input.strip.chomp.presence

      if data.nil?
        raise Nacha::ParserError.new("No valid ACH data found")
      end

      lines = data.split("\n")
      raw_data["batches"] = [] of Hash(String, String | Array(String))

      lines.each do |line|
        case line[0].to_i
        when 1
          raw_data["file_header"] = line
        when 9
          if line_is_padding?(line)
            # padding... do I need this?
          else
            raw_data["file_control"] = line
          end
        else
          current_batch = raw_data["batches"].as(Array).last?
          if current_batch
            insert_into_batch(current_batch, line)
          else
            raw_data["batches"].as(Array).push({} of String => String | Array(String))
            insert_into_batch(raw_data["batches"].as(Array).first, line)
          end
        end
      end

      file_header = Nacha::FileHeader.parse(raw_data["file_header"].as(String))
      batches = [] of Nacha::Batch
      raw_data["batches"].as(Array).each do |batch_data|
        batch_header = Nacha::BatchHeader.parse(batch_data["batch_header"].as(String))

        entries = [] of Nacha::EntryDetail
        batch_data["entries"].as(Array).each do |entry_data|
          entries << Nacha::EntryDetail.parse(entry_data)
        end

        batches << Nacha::Batch.new(header: batch_header, entries: entries)
      end

      Nacha::File.new(header: file_header, batches: batches)
    end

    private def insert_into_batch(batch : Hash(String, String | Array(String)), line : String) : Nil
      type = line[0].to_i
      case type
      when 5
        batch["batch_header"] = line
      when 6, 7
        batch["entries"] ||= [] of String
        batch["entries"].as(Array).push(line)
      when 8
        batch["batch_control"] = line
      end
    end

    private def line_is_padding?(line) : Bool
      line == ("9" * Nacha::File::RECORD_SIZE)
    end
  end
end
