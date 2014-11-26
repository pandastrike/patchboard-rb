Gem::Specification.new do |s|
  s.name = "patchboard"
  s.version = "0.5.2"
  s.authors = ["Matthew King"]
  s.email = "automatthew@gmail.com"
  s.homepage = "https://github.com/pandastrike/patchboard-rb"
  s.summary = "Ruby client for Patchboard APIs"

  s.files = %w[
    LICENSE
    README.md
  ] + Dir["lib/**/*.rb"]
  s.license = "MIT"
  s.require_path = "lib"

  s.add_dependency("json", "~> 1.8")
  s.add_dependency("http", "~> 0.5")
  s.add_dependency("hashie", "~> 2.0")

  s.add_development_dependency("minitest-reporters", "~> 1.0")
end
