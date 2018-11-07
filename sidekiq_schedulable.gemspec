lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq_schedulable/version'

Gem::Specification.new do |spec|
  spec.name          = "sidekiq_schedulable"
  spec.version       = SidekiqSchedulable::VERSION
  spec.authors       = ["Kevin Buchanan"]
  spec.summary       = "Scheduled Sidekiq jobs"
  spec.description   = "Schedule Cron style Sidekiq jobs"
  spec.homepage      = "https://github.com/kevinbuch/sidekiq_schedulable"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", ">= 5.0"
  spec.add_dependency "parse-cron", "~> 0.1"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "timecop", "~> 0.8"
end
