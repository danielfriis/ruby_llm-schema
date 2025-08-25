#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/ruby_llm/schema"

# Define reusable schema classes
class PersonSchema < RubyLLM::Schema
  string :name, description: "Person's full name"
  integer :age, description: "Person's age"
end

class AddressSchema < RubyLLM::Schema
  string :street, description: "Street address"
  string :city, description: "City name"
  string :zipcode, description: "Postal code"
end

# Define a CompanySchema using inline schema insertion
class CompanySchema < RubyLLM::Schema
  string :name, description: "Company name"

  # Arrays with inline schema insertion
  array :employees, of: PersonSchema, description: "Company employees"

  # Objects with inline schema insertion
  object :founder, of: PersonSchema, description: "Company founder"
  object :headquarters, of: AddressSchema, description: "Main office"

  # Mixed usage - Schema.new in blocks still works
  object :ceo do
    PersonSchema.new
  end

  # Users can still use explicit definitions when they want shared references
  define :department do
    string :name
    integer :employee_count
  end

  array :departments, of: :department, description: "Company departments"
end

# Generate and display the JSON schema
company = CompanySchema.new("CompanyExample")
json_output = company.to_json_schema

puts "=== Inline Schema Example ==="
puts "Notice how PersonSchema and AddressSchema are embedded directly where used,"
puts "while :department uses a shared definition.\n\n"

puts JSON.pretty_generate(json_output)
