require 'bundler/gem_tasks'
require 'rake/clean'
require 'rspec/core/rake_task'

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rspec_opts = ['-I lib -fd -fd --out ./testresults/testresults.log -fh --out ./testresults/testresults.html']
  # Put spec opts in a file named .rspec in root
end

task :default do
  sh "rake -T"
end

