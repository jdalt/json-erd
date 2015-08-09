$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "json-erd/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "json-erd"
  s.version     = JsonErd::VERSION
  s.authors     = ["Jacob Dalton"]
  s.email       = ["jacobrdalton@gamil.com"]
  s.homepage    = "http://github.com/jdalt/json-erd"
  s.summary     = "Generates json erd based on AR and Mongoid models"
  s.description = "A rake tasks that generates a json erd description of all of you ActiveRecord and Mongoid models."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.21"

  s.add_development_dependency "sqlite3"
end
