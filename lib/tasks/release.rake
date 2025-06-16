namespace :release do
  desc "Release a new version of the gem"
  task :version do
    puts "Enter the new version: "
    version = gets.chomp
    system "git tag v#{version}"
    system "git push origin v#{version}"

    system "gem build ruby_llm-schema.gemspec"
    system "gem push ruby_llm-schema-#{version}.gem"
    system "rm ruby_llm-schema-#{version}.gem"
  end
end
