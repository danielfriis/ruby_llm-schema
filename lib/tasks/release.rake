namespace :release do
  desc "Release a new version of the gem"
  task :version do
    # Load the current version from version.rb
    require_relative '../../lib/ruby_llm/schema/version'
    version = RubyLlm::Schema::VERSION
    
    puts "Releasing version #{version}..."
    
    # Prompt for release message
    print "Enter release message (optional): "
    release_message = STDIN.gets.chomp
    
    # Create git tag with message
    if release_message.empty?
      system "git tag v#{version}"
    else
      system "git tag -a v#{version} -m \"#{release_message}\""
    end
    
    system "git push origin main"
    system "git push origin v#{version}"

    system "gem build ruby_llm-schema.gemspec"
    system "gem push ruby_llm-schema-#{version}.gem"
    system "rm ruby_llm-schema-#{version}.gem"
  end
end
