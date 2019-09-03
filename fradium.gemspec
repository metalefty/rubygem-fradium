
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fradium/version"

Gem::Specification.new do |spec|
  spec.name          = "fradium"
  spec.version       = Fradium::VERSION
  spec.authors       = ["Koichiro IWAO"]
  spec.email         = ["meta@vmeta.jp"]

  spec.summary       = %q{fradium - FreeRADIUS User Manager}
  spec.description   = %q{Quick User Management Tool for FreeRADIUS}
  spec.homepage      = "https://github.com/metalefty/fradium"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.5.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'pry', '~> 0.12'

  spec.add_dependency 'mysql2', '~> 0.5'
  spec.add_dependency 'sqlite3', '~> 1.4'
  spec.add_dependency 'pg', '~> 1.1'
  spec.add_dependency 'sequel', '~> 5.23'
end
