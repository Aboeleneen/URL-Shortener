#!/usr/bin/env ruby
# run_tests.rb
require 'rspec/core'

puts "🧪 Running RSpec tests..."
puts "=" * 50

# Run RSpec
RSpec::Core::Runner.run(['spec/'])

puts "=" * 50
puts "✅ Tests completed!"
