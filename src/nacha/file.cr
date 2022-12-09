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
        block_count: block_count_for_control,
        entry_count: @batches.sum(0, &.entries.size),
        entry_hash: entry_hash.to_i64,
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

      control.build(io)

      if (row_count % 10) > 0
        padding_needed = 10 - row_count
        padding_needed.times do
          io << "\n"
          io << "9" * Nacha::File::RECORD_SIZE
        end
      end

      io
    end

    def row_count : Int32
      header.row_count + batches.sum(0, &.row_count) + control.row_count
    end

    private def entry_hash : String
      total = @batches.sum(0, &.entry_hash.to_i).to_s
      if total.bytesize > 10
        total[-10..-1]
      else
        total.rjust(10, '0')
      end
    end

    private def block_count_for_control : Int32
      control_row = 1
      rows = @header.row_count + @batches.sum(0, &.row_count) + control_row
      (rows / 10).ceil.to_i
    end
  end
end
