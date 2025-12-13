# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, ".strict" do
  it "defaults to true when not set" do
    schema = Class.new(RubyLLM::Schema)
    expect(schema.strict).to eq(true)
  end

  it "returns nil when set to nil" do
    schema = Class.new(RubyLLM::Schema) { strict nil }
    expect(schema.strict).to eq(nil)
  end

  it "returns true when set to true" do
    schema = Class.new(RubyLLM::Schema) { strict true }
    expect(schema.strict).to eq(true)
  end

  it "returns false when set to false" do
    schema = Class.new(RubyLLM::Schema) { strict false }
    expect(schema.strict).to eq(false)
  end
end
