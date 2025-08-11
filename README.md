# RubyLLM::Schema

A Ruby DSL for creating JSON schemas with a clean, Rails-inspired API. Perfect for defining structured data schemas for LLM function calling or structured outputs.

## Use Cases

Structured output is a powerful tool for LLMs to generate consistent and predictable responses.

Some ideal use cases:

- Extracting *metadata, topics, and summary* from articles or blog posts
- Organizing unstructured feedback or reviews with *sentiment and summary* 
- Defining structured *actions* from user messages or emails
- Extracting *entities and relationships* from documents

### Simple Example

```ruby
class PersonSchema < RubyLLM::Schema
  string :name, description: "Person's full name"
  number :age, description: "Age in years", minimum: 0, maximum: 120
  boolean :active, required: false
  
  object :address do
    string :street
    string :city
    string :country, required: false
  end
  
  array :tags, of: :string, description: "User tags"
  
  array :contacts do
    object do
      string :email, format: "email"
      string :phone, required: false
    end
  end
  
  any_of :status do
    string enum: ["active", "pending", "inactive"]
    null
  end
end

# Usage
schema = PersonSchema.new
puts schema.to_json
```

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

Three approaches for creating schemas:

### Class Inheritance

```ruby
class PersonSchema < RubyLLM::Schema
  string :name, description: "Person's full name"
  number :age
  boolean :active, required: false
  
  object :address do
    string :street
    string :city
  end
  
  array :tags, of: :string
end

schema = PersonSchema.new
puts schema.to_json
```

### Factory Method

```ruby
PersonSchema = RubyLLM::Schema.create do
  string :name, description: "Person's full name"
  number :age
  boolean :active, required: false
  
  object :address do
    string :street
    string :city
  end
  
  array :tags, of: :string
end

schema = PersonSchema.new
puts schema.to_json
```

### Global Helper

```ruby
require 'ruby_llm/schema'
include RubyLLM::Helpers

person_schema = schema "PersonData", description: "A person object" do
  string :name, description: "Person's full name"
  number :age
  boolean :active, required: false
  
  object :address do
    string :street
    string :city
  end
  
  array :tags, of: :string
end

puts person_schema.to_json
```

## Schema Property Types

A schema is a collection of properties, which can be of different types. Each type has its own set of properties you can set.

All property types can (along with the required `name` key) be set with a `description` and a `required` flag (default is `true`).

```ruby
string :name, description: "Person's full name"
number :age, description: "Person's age", required: false
boolean :is_active, description: "Whether the person is active"
null :placeholder, description: "A placeholder property"
```

⚠️ Please consult the LLM provider documentation for any limitations or restrictions. For example, as of now, OpenAI requires all properties to be required. In that case, you can use the `optional` method to make a property optional.

### Strings

String types support the following properties:

- `enum`: an array of allowed values (e.g. `enum: ["on", "off"]`)
- `pattern`: a regex pattern (e.g. `pattern: "\\d+"`)
- `format`: a format string (e.g. `format: "email"`)
- `min_length`: the minimum length of the string (e.g. `min_length: 3`)
- `max_length`: the maximum length of the string (e.g. `max_length: 10`)

Please consult the LLM provider documentation for the available formats and patterns.

```ruby
string :name, description: "Person's full name"
string :email, format: "email"
string :phone, pattern: "\\d+"
string :status, enum: ["on", "off"]
string :code, min_length: 3, max_length: 10
```

### Numbers

Number types support the following properties:

- `multiple_of`: a multiple of the number (e.g. `multiple_of: 0.01`)
- `minimum`: the minimum value of the number (e.g. `minimum: 0`)
- `maximum`: the maximum value of the number (e.g. `maximum: 100`)

```ruby
number :price, minimum: 0, maximum: 100
number :amount, multiple_of: 0.01
```

### Booleans

```ruby
boolean :is_active
```

Boolean types doesn't support any additional properties.

### Null

```ruby
null :placeholder
```

Null types doesn't support any additional properties.

### Arrays

An array is a list of items. You can set the type of the items in the array with the `of` option or by passing a block with the `object` method.

An array can have a `min_items` and `max_items` option to set the minimum and maximum number of items in the array.

```ruby
array :tags, of: :string              # Array of strings
array :scores, of: :number            # Array of numbers
array :items, min_items: 1, max_items: 10  # Array with size constraints

array :items do                       # Array of objects
  object do
    string :name
    number :price
  end
end
```

### Objects

Objects types expect a block with the properties of the object.

```ruby
object :user do
  string :name
  number :age
end

object :settings, description: "User preferences" do
  boolean :notifications
  string :theme, enum: ["light", "dark"]
end
```

### Union Types (anyOf)

Union types are a way to specify that a property can be one of several types.

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

### Optionals

Optional types are a way to specify that a property is optional. Under the hood, this is a union type with a `null` type.

```ruby
optional :name, description: "Person's full name"

# is the same as
any_of :name, description: "Person's full name" do
  string
  null
end
```

### Schema Definitions and References

You can define sub-schemas and reference them in other schemas.

```ruby
class MySchema < RubyLLM::Schema
  define :location do
    string :latitude
    string :longitude
  end
  
  array :coordinates, of: :location
  
  object :home_location do
    reference :location
  end
end
```

## JSON Output

```ruby
schema = PersonSchema.new
schema.to_json_schema
# => {
#   name: "PersonSchema",
#   description: nil,
#   schema: {
#     type: "object",
#     properties: { ... },
#     required: [...],
#     additionalProperties: false,
#     strict: true
#   }
# }

puts schema.to_json  # Pretty JSON string
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
