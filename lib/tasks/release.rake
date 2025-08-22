namespace :release do
  desc "Release a new version of the gem"
  task :version, [:message] do |t, args|
    # Load the current version from version.rb
    require_relative "../../lib/ruby_llm/schema/version"
    version = RubyLlm::Schema::VERSION

    puts "Releasing version #{version}..."

    # Create git tag with optional message
    # rake release:version["Fix critical bug in schema validation"]
    if args[:message]
      system "git tag -a v#{version} -m \"#{args[:message]}\""
      puts "Created annotated tag v#{version} with message: #{args[:message]}"
    else
      system "git tag v#{version}"
      puts "Created lightweight tag v#{version}"
    end

    system "git push origin main"
    system "git push origin v#{version}"

    system "gem build ruby_llm-schema.gemspec"
    system "gem push ruby_llm-schema-#{version}.gem"
    system "rm ruby_llm-schema-#{version}.gem"
  end
end
