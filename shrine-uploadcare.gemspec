Gem::Specification.new do |gem|
  gem.name          = "shrine-uploadcare"
  gem.version       = "0.2.0"

  gem.required_ruby_version = ">= 2.1"

  gem.summary      = "Provides Uploadcare storage for Shrine."
  gem.homepage     = "https://github.com/janko-m/shrine-uploadcare"
  gem.authors      = ["Janko Marohnić"]
  gem.email        = ["janko.marohnic@gmail.com"]
  gem.license      = "MIT"

  gem.files        = Dir["README.md", "LICENSE.txt", "lib/**/*.rb", "*.gemspec"]
  gem.require_path = "lib"

  gem.add_dependency "shrine", "~> 2.2"
  gem.add_dependency "uploadcare-ruby", "~> 1.0.5"
  gem.add_dependency "down", ">= 2.3.3"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "dotenv"
end
