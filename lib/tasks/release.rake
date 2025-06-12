namespace :release do
  desc "Release a new version of the gem"
  task :version do
    puts "Enter the new version: "
    version = gets.chomp
    system "git tag v#{version}"
    system "git push origin v#{version}"
  end
end
