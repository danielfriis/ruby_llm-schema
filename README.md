# RubyLlm::Schema

A Ruby DSL for creating JSON schemas with a clean, Rails-inspired API. Perfect for defining structured data schemas for LLM function calling, API validation, or any application requiring JSON schema definitions.

## Features

<!-- TODO -->

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_llm-schema'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install ruby_llm-schema
```

## Usage

### Basic Schema Definition

<!-- TODO -->

### Field Types

<!-- TODO -->

### Optional Fields

<!-- TODO -->

### String Enums

<!-- TODO -->

### Arrays

<!-- TODO -->

### Nested Objects

<!-- TODO -->

### Union Types (anyOf)

<!-- TODO -->


### Error Handling

<!-- TODO -->

### Complete Example

<!-- TODO -->

## API Reference

### Field Methods

- `string(name, enum: nil, description: nil, required: true)`
- `number(name, description: nil, required: true)`  
- `boolean(name, description: nil, required: true)`
- `null(name, description: nil, required: true)`
- `object(name, description: nil, required: true, &block)`
- `array(name, of: nil, description: nil, required: true, &block)`
- `schema(name, schema_class, description: nil, required: true)`
- `any_of(name, schemas, description: nil, required: true)`

### Schema Methods

- `to_json_schema` - Returns Hash with complete JSON schema
- `to_json` - Returns pretty-printed JSON string
- `validate_schema!` - Validates schema definition

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ruby_llm-schema.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
