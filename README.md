# RubyLLM::Schema

A Ruby DSL for creating JSON schemas with a clean, Rails-inspired API. Perfect for defining structured data schemas for LLM function calling, API validation, or any application requiring JSON schema definitions.

## Features

- **Three Beautiful APIs**: Choose the syntax that fits your use case
- **Type Safety**: Built-in validation for schema definitions
- **Nested Objects**: Full support for complex nested structures
- **Array Support**: Arrays of primitives or complex objects
- **Union Types**: `anyOf` support for flexible schemas
- **Schema Reuse**: Define reusable schema components
- **Rails-style DSL**: Clean, readable syntax following Ruby conventions

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

RubyLLM::Schema provides three approaches for creating schemas, optimized for different use cases:

### 1. Class Inheritance (Best for reusable schemas)

Perfect when you need a reusable schema class that can be instantiated multiple times or extended.

```ruby
class PersonSchema < RubyLLM::Schema
  string :name, description: "Person's full name"
  number :age, description: "Age in years"
  boolean :active, required: false
  
  object :address do
    string :street
    string :city
    string :country, required: false
  end
  
  array :tags, of: :string, description: "User tags"
  
  array :contacts do
    object do
      string :email
      string :phone, required: false
    end
  end
  
  any_of :status do
    string enum: ["active", "pending", "inactive"]
    null
  end
end

# Usage
schema = PersonSchema.new("PersonData", "A person object")
puts schema.to_json
```

### 2. Factory Method (Best for one-off schemas)

Ideal for creating schema classes without explicit inheritance, reducing boilerplate for simple cases.

```ruby
PersonSchema = RubyLLM::Schema.create do
  string :name, description: "Person's full name"
  number :age
  boolean :active, required: false
  
  object :address do
    string :street
    string :city
  end
end

# Usage
schema = PersonSchema.new("PersonData")
puts schema.to_json
```

### 3. Global Helper (Best for inline schemas)

Perfect for creating schema instances directly without defining classes. Requires including the helper module.

```ruby
require 'ruby_llm/schema'
include RubyLLM::Helpers

# Named schema with description
person_schema = schema "PersonData", "A person object" do
  string :name, description: "Person's full name"
  number :age
  boolean :active, required: false
  
  object :address do
    string :street
    string :city
  end
end

# Minimal syntax
simple_schema = schema do
  string :title
  number :count
end

puts person_schema.to_json
```

## Field Types

### Basic Types

```ruby
string :name                          # Required string
string :title, required: false       # Optional string  
string :status, enum: ["on", "off"]  # String with enum values
number :count                         # Required number
boolean :active                       # Required boolean
null :placeholder                     # Null type
```

### Complex Types

#### Objects
```ruby
object :user do
  string :name
  number :age
end

# With description
object :settings, description: "User preferences" do
  boolean :notifications
  string :theme, enum: ["light", "dark"]
end
```

#### Arrays
```ruby
# Array of primitives
array :tags, of: :string
array :scores, of: :number

# Array of objects
array :items do
  object do
    string :name
    number :price
  end
end
```

#### Union Types (anyOf)
```ruby
any_of :value do
  string
  number  
  null
end

any_of :identifier do
  string description: "Username"
  number description: "User ID"
end
```

### Schema Definitions and References

Create reusable schema components:

```ruby
class MySchema < RubyLLM::Schema
  # Define a reusable schema component
  define :location do
    string :latitude
    string :longitude
  end
  
  # Reference it in arrays
  array :coordinates, of: :location
  
  # Or use directly
  object :home_location do
    reference :location
  end
end
```

## Complete Examples

### API Response Schema
```ruby
ApiResponseSchema = RubyLLM::Schema.create do
  boolean :success
  string :message, required: false
  
  object :data, required: false do
    array :users do
      object do
        string :id
        string :name
        string :email
        boolean :verified, required: false
      end
    end
    
    object :pagination do
      number :page
      number :total_pages
      number :total_count
    end
  end
  
  any_of :error, required: false do
    string description: "Error message"
    object do
      string :code
      string :message
      array :details, of: :string, required: false
    end
  end
end
```

### LLM Function Schema
```ruby
include RubyLLM::Helpers

weather_function = schema "get_weather", description: "Get current weather for a location" do
  string :location, description: "City name or coordinates"
  string :units, enum: ["celsius", "fahrenheit"], required: false
  boolean :include_forecast, required: false
end
```

## JSON Output

All schemas generate complete JSON Schema objects:

```ruby
schema = PersonSchema.new
schema.to_json_schema
# => {
#   name: "PersonData",
#   description: "A person object", 
#   schema: {
#     type: "object",
#     properties: { ... },
#     required: [...],
#     additionalProperties: false,
#     strict: true,
#     "$defs": { ... }
#   }
# }

# Pretty JSON string
puts schema.to_json
```

## Best Practices

1. **Use descriptive names and descriptions** for better LLM understanding
2. **Mark fields as optional when appropriate** using `required: false`
3. **Use enums for constrained string values** to improve validation
4. **Group related fields in objects** for better organization
5. **Define reusable components** with `define` for common patterns
6. **Choose the right approach**:
   - **Class inheritance**: Reusable schemas, complex inheritance
   - **Factory method**: Simple one-off schema classes  
   - **Global helper**: Quick inline schemas, scripting

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ruby_llm-schema.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
