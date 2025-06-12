# RubyLlm::Schema

A Ruby DSL for creating JSON schemas with a clean, Rails-inspired API. Perfect for defining structured data schemas for LLM function calling, API validation, or any application requiring JSON schema definitions.

## Features

- 🎯 **Clean, intuitive DSL** - Ruby-esque syntax that feels natural
- 🔧 **Optional & Required Fields** - Fine-grained control over field requirements  
- 🏗️ **Schema Composition** - Embed schemas within other schemas
- 🔍 **Smart Validation** - Circular reference detection and field name validation
- 🎨 **Flexible Arrays** - Support for typed arrays and complex object arrays
- 🛡️ **Type Safety** - Comprehensive error handling with descriptive messages

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

```ruby
require 'ruby_llm/schema'

# Method 1: Class-based definition
class PersonSchema < RubyLlm::Schema
  string :name, description: 'Full name'
  number :age, description: 'Age in years'
  boolean :active, description: 'Whether user is active'
end

# Method 2: Define method
PersonSchema = RubyLlm::Schema.define do
  string :name, description: 'Full name'
  number :age, description: 'Age in years' 
  boolean :active, description: 'Whether user is active'
end

# Method 3: Global helper
PersonSchema = schema do
  string :name, description: 'Full name'
  number :age, description: 'Age in years'
  boolean :active, description: 'Whether user is active'
end

# Generate JSON Schema
person = PersonSchema.new('Person')
json_schema = person.to_json_schema
# Returns: { name: "Person", description: "Schema for...", schema: {...} }
```

### Field Types

```ruby
UserSchema = schema do
  string :username, description: 'Unique username'
  number :score, description: 'User score'
  boolean :verified, description: 'Email verified status'  
  null :deleted_at, description: 'Deletion timestamp'
end
```

### Optional Fields

```ruby
ProfileSchema = schema do
  # Required fields (default)
  string :username
  string :email
  
  # Individual optional fields
  string :bio, required: false
  number :age, required: false
  
  # Grouped optional fields
  optional do
    string :middle_name
    string :nickname
    string :website
  end
end
```

### String Enums

```ruby
StatusSchema = schema do
  string :status, enum: %w[active pending suspended], description: 'Account status'
  string :role, enum: %w[user admin moderator], description: 'User role'
end
```

### Arrays

```ruby
BlogSchema = schema do
  string :title
  
  # Simple typed arrays
  array :tags, of: :string, description: 'Post tags'
  array :scores, of: :number, description: 'Rating scores'
  array :flags, of: :boolean, description: 'Feature flags'
  
  # Array of objects with inline definition
  array :comments, description: 'User comments' do
    string :text
    string :author  
    number :timestamp
  end
  
  # Array referencing another schema
  array :related_posts, of: PostSchema
end
```

### Nested Objects

```ruby
UserSchema = schema do
  string :name
  string :email
  
  # Inline object definition
  object :preferences, description: 'User preferences' do
    boolean :notifications
    string :theme, enum: %w[light dark]
    number :font_size
  end
  
  # Optional nested object
  object :profile, required: false do
    string :bio
    string :website
  end
end
```

### Schema Composition

```ruby
# Define reusable schemas
AddressSchema = schema do
  string :street
  string :city  
  string :country
  string :postal_code
end

ContactSchema = schema do
  string :email
  string :phone, required: false
end

# Compose them in other schemas
UserSchema = schema do
  string :name
  number :age
  
  # Embed other schemas
  schema :address, AddressSchema, description: 'User address'
  schema :contact, ContactSchema, description: 'Contact information'
  
  # Optional embedded schema
  schema :billing_address, AddressSchema, required: false
end
```

### Union Types (anyOf)

```ruby
PaymentSchema = schema do
  # Union of different types
  any_of :amount, [
    RubyLlm::Schema.number_type(description: 'Amount in cents'),
    RubyLlm::Schema.string_type(enum: %w[free trial], description: 'Special pricing')
  ]
  
  # Nullable fields using anyOf
  any_of :discount, [
    RubyLlm::Schema.number_type(description: 'Discount percentage'),
    RubyLlm::Schema.null_type
  ]
end
```

### Schema References

```ruby
# Define schemas for reuse
RubyLlm::Schema.define_schema(:user) do
  string :name
  string :email
end

# Reference them in other schemas  
PostSchema = schema do
  string :title
  string :content
  schema :author, UserSchema  # Direct class reference
  array :collaborators, of: :user  # Symbol reference
end
```

### Error Handling

```ruby
# The gem provides comprehensive error handling
begin
  BadSchema = schema do
    string :'invalid-name'  # Invalid field name
  end
rescue RubyLlm::Schema::InvalidSchemaError => e
  puts e.message  # "Invalid field names: invalid-name. Field names must be valid identifiers."
end

# Circular reference detection
begin
  PersonSchema = schema do
    string :name
    schema :friend, PersonSchema  # This would create a circular reference
  end
rescue RubyLlm::Schema::CircularReferenceError => e
  puts e.message  # "Circular reference detected: ..."
end
```

### Complete Example

```ruby
# E-commerce order schema
OrderSchema = schema do
  string :id, description: 'Unique order identifier'
  string :status, enum: %w[pending processing shipped delivered cancelled]
  number :total, description: 'Total amount in cents'
  
  # Customer information
  object :customer do
    string :name
    string :email
    
    schema :address, AddressSchema
    
    optional do
      string :phone
    end
  end
  
  # Order items
  array :items, description: 'Ordered items' do
    string :product_id
    string :name
    number :quantity
    number :price, description: 'Price per item in cents'
    
    optional do
      string :variant
      array :customizations, of: :string
    end
  end
  
  # Payment information
  object :payment, required: false do
    string :method, enum: %w[credit_card paypal bank_transfer]
    string :status, enum: %w[pending completed failed]
    
    any_of :amount, [
      RubyLlm::Schema.number_type(description: 'Amount in cents'),
      RubyLlm::Schema.null_type
    ]
  end
  
  # Metadata
  optional do
    array :tags, of: :string
    object :metadata do
      string :source, required: false
      string :campaign_id, required: false
    end
  end
end

# Generate the schema
order = OrderSchema.new('Order')
puts order.to_json  # Pretty-printed JSON schema
```

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

### Helper Methods

- `optional(&block)` - Make all fields in block optional
- `string_type(enum: nil, description: nil)` - Create string type definition
- `number_type(description: nil)` - Create number type definition  
- `boolean_type(description: nil)` - Create boolean type definition
- `null_type(description: nil)` - Create null type definition

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
