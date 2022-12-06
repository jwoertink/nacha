# Nacha

> The ACH file format (or NACHA file) is a text file with ASCII text lines, where each line is 94 characters long and serves as a “record” to execute domestic ACH payments through the Automated Clearing House Network (NACHA).
- https://tipalti.com/nacha-file-format/

This Crystal shard allows you to generate or parse a NACHA file.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     nacha:
       github: jwoertink/nacha
   ```

2. Run `shards install`

## Usage

```crystal
require "nacha"

entries = [
  Nacha::EntryDetail.new,
  Nacha::EntryDetail.new,
] of Nacha::EntryDetail

batches = [
  Nacha::Batch.new(
    header: Nacha::BatchHeader.new,
    entries: entries,
    control: Nacha::BatchControl.new,
  ),
] of Nacha::Batch

ach_file = Nacha::File.new(
  header: Nacha::FileHeader.new,
  batches: batches,
  control: Nacha::FileControl.new,
)

puts ach_file.generate
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/jwoertink/nacha/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jeremy Woertink](https://github.com/jwoertink) - creator and maintainer
