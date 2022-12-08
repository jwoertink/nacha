module Nacha
  class File
    include BuildableRecord

    RECORD_SIZE     = 94  # The number of bytes per record row
    BLOCKING_FACTOR = 10  # All files must have line numbers divisible by 10
    FORMAT_CODE     = '1' # Placeholder for future other formats

    getter header : Nacha::FileHeader
    getter batches : Array(Nacha::Batch)
    getter control : Nacha::FileControl
    private property line_count : Int32 = 0

    def initialize(@header : FileHeader, @batches : Array(Batch))
      @control = FileControl.new(
        batch_count: @batches.size,
        block_count: 1, # TODO: what's the proper value for this?
        entry_count: @batches.sum(0, &.entries.size),
        entry_hash: entry_hash,
        total_debit_amount: @batches.sum(0, &.total_debit_amount),
        total_credit_amount: @batches.sum(0, &.total_credit_amount),
      )
    end

    def generate : String
      String.build do |io|
        build(io)
      end
    end

    def build(io : IO) : IO
      header.build(io)
      io << "\n"
      batches.each do |batch|
        batch.build(io)
        io << "\n"
      end
      # count current lines, add 1 (for the next line)
      # figure out how many padding lines we need
      # do the math
      # oh, you have 2 blocks
      # control.block_count = 2
      # no continue like normal
      control.build(io)

      lines = io.to_s.split("\n")
      count = lines.size % 10
      if count > 0
        padding_needed = 10 - count
        padding_needed.times do
          io << "\n"
          io << "9" * Nacha::File::RECORD_SIZE
        end
      end

      io
    end

    private def entry_hash : String
      total = @batches.sum(0, &.entry_hash.to_i).to_s
      if total.bytesize > 10
        total[-10..-1]
      else
        total.rjust(10, '0')
      end
    end
  end
end
