$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "vkontakte/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "vkontakte"
  s.version     = Vkontakte::VERSION
  s.authors     = ["Sergey Tsvetkov"]
  s.email       = ["sergey.a.tsvetkov@gmail.com"]
  s.homepage    = "http://vkshop.kimrgrey.org"
  s.summary     = ""
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.8"
end
