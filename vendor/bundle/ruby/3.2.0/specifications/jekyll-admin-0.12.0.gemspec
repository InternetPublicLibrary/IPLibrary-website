# -*- encoding: utf-8 -*-
# stub: jekyll-admin 0.12.0 ruby lib

Gem::Specification.new do |s|
  s.name = "jekyll-admin".freeze
  s.version = "0.12.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 2.7.0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mert Kahyao\u011Flu".freeze, "GitHub Open Source".freeze]
  s.date = "2025-02-27"
  s.description = "Jekyll::Admin is a drop in administrative framework for Jekyll sites.".freeze
  s.email = ["mertkahyaoglu93@gmail.com".freeze, "opensource@github.com".freeze]
  s.homepage = "https://github.com/jekyll/jekyll-admin".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "wp-admin for Jekyll, but better".freeze

  s.installed_by_version = "3.6.9".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<jekyll>.freeze, [">= 3.7".freeze, "< 5.0".freeze])
  s.add_runtime_dependency(%q<rackup>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<sinatra>.freeze, ["~> 4.0".freeze])
  s.add_runtime_dependency(%q<sinatra-contrib>.freeze, ["~> 4.0".freeze])
end
