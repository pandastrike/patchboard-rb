Gem::Specification.new do |s|
  s.name = "patchboard"
  s.version = "0.1.0"
  s.authors = ["Matthew King"]
  s.homepage = "https://github.com/pandastrike/patchboard-rb"
  s.summary = "Ruby client for Patchboard APIs"

  s.files = %w[
    LICENSE
    README.md
  ] + Dir["lib/**/*.rb"]
  s.license = "MIT"
  s.require_path = "lib"

  s.add_dependency("json", ">=1.7.5")
  s.add_dependency("json-schema", "~> 1.0.10")
  s.add_development_dependency("starter", ">= 0.1.7")
  s.add_development_dependency("rspec", ">= 2.12.0")
end
