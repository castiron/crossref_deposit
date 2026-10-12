# frozen_string_literal: true

require_relative "lib/crossref_deposit/version"

Gem::Specification.new do |spec|
  spec.name = "crossref_deposit"
  spec.version = CrossrefDeposit::VERSION
  spec.authors = [ "Tim Frazee" ]
  spec.email = [ "tim@castironcoding.com" ]

  spec.summary = "Build, validate, and submit CrossRef deposit (doi_batch) XML to register DOIs."
  spec.description = <<~TEXT
                    A Ruby library for minting DOIs with CrossRef via their XML deposit API
                    TEXT
  spec.homepage = "https://github.com/castiron/crossref_deposit"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "vendor/schema/**/*", "README.md", "LICENSE"]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-multipart", "~> 1.0"
  spec.add_dependency "nokogiri", "~> 1.15"
end
