# TODO: put these as methods on PatchboardTests
$project_root = File.expand_path("#{File.dirname(__FILE__)}/..")
$LOAD_PATH.unshift "#{$project_root}/lib"

require "pp"
require "json"
require "patchboard"

module PatchboardTests
  module_function

  def api_path
    "#{$project_root}/node_modules/patchboard-api/test_api.json"
  end

  def api_def
    @api_def ||= begin
      data = JSON.parse(File.read(api_path), :symbolize_names => true)
      data[:schemas] = [data.delete(:schema)]
      data
    end
  end

  def api
    Patchboard::API.new(api_def)
  end

  def client
    Patchboard.new(api_def, :namespace => PatchboardTests)
  end
end

