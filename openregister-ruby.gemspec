# -*- encoding: utf-8 -*-
# stub: openregister-ruby 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "openregister-ruby".freeze
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rob McKinnon".freeze]
  s.date = "2016-07-18"
  s.email = "rob ~@nospam@~ rubyforge.org".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "lib/openregister.rb".freeze]
  s.homepage = "https://github.com/robmckinnon/openregister-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubygems_version = "2.6.4".freeze
  s.summary = "A Ruby API to the UK government data registers.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<morph>.freeze, ["~> 0.5.0"])
      s.add_runtime_dependency(%q<rest-client>.freeze, ["~> 1"])
      s.add_development_dependency(%q<guard-rspec>.freeze, ["~> 4"])
      s.add_development_dependency(%q<webmock>.freeze, ["~> 2"])
    else
      s.add_dependency(%q<morph>.freeze, ["~> 0.5.0"])
      s.add_dependency(%q<rest-client>.freeze, ["~> 1"])
      s.add_dependency(%q<guard-rspec>.freeze, ["~> 4"])
      s.add_dependency(%q<webmock>.freeze, ["~> 2"])
    end
  else
    s.add_dependency(%q<morph>.freeze, ["~> 0.5.0"])
    s.add_dependency(%q<rest-client>.freeze, ["~> 1"])
    s.add_dependency(%q<guard-rspec>.freeze, ["~> 4"])
    s.add_dependency(%q<webmock>.freeze, ["~> 2"])
  end
end
