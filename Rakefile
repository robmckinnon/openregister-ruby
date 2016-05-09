require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
require './lib/openregister'

require 'rspec'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w(--format documentation --colour)
end

task default: ['spec']

spec = Gem::Specification.new do |s|

  s.name              = 'openregister-ruby'
  s.version           = OpenRegister::VERSION
  s.summary           = 'A Ruby API to the UK government data registers.'
  s.author            = 'Rob McKinnon'
  s.email             = 'rob ~@nospam@~ rubyforge.org'
  s.homepage          = 'https://github.com/robmckinnon/openregister-ruby'
  s.licenses          = ['MIT']

  s.has_rdoc          = false
  s.extra_rdoc_files  = %w(README.md)
  s.rdoc_options      = %w(--main README.md)

  s.files             = %w(Gemfile LICENSE README.md) + Dir.glob('{lib}/**/*')
  s.require_paths     = ['lib']

  s.add_runtime_dependency 'morph', '~> 0.4.1'
  s.add_runtime_dependency 'rest-client', '~> 1'

  s.add_development_dependency 'guard-rspec', '~> 4'
  s.add_development_dependency 'webmock', '~> 2'
end

# This task actually builds the gem.
Gem::PackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Build the gemspec file #{spec.name}.gemspec"
task :gemspec do
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, 'w') {|f| f << spec.to_ruby }
end

task package: :gemspec

RDoc::Task.new do |rd|
  rd.main = 'README.md'
  rd.rdoc_files.include('README.md', 'lib/**/*.rb')
  rd.rdoc_dir = 'rdoc'
end

desc 'Clear out RDoc and generated packages'
task clean: [:clobber_rdoc, :clobber_package] do
  rm "#{spec.name}.gemspec"
end
