$:.unshift "/Users/matthew/projects/oss/starter/lib"
require "starter/tasks/gems"
require "starter/tasks/git"

task "test" => %w[ test:unit ]

task "test:unit" do
  gem "minitest"
  require "minitest/autorun"
  require "minitest/reporters"
  Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new()]
  $:.unshift File.expand_path("./lib", File.dirname(__FILE__))
  FileList['./test/unit/*.rb'].each { |file| require file}
end

