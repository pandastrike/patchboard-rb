require "json"
gem "minitest"
require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new()]
$:.unshift File.expand_path("../lib", File.dirname(__FILE__))

require "patchboard/api"
module PatchboardTests
  module_function
  def api
    api_path = File.expand_path(
      "#{File.dirname(__FILE__)}/../../patchboard/src/example_api.json"
    )

    data = JSON.parse(File.read(api_path), :symbolize_names => true)
    data[:schemas] = [data.delete(:schema)]
    Patchboard::API.new(data)
  end
end
