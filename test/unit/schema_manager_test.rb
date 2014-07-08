require_relative "setup"
require "patchboard/schema_manager"

def media_type(name)
  "application/vnd.gh-knockoff.#{name}+json"
end

api = PatchboardTests.api
schema_manager = Patchboard::SchemaManager.new(api.schemas)
#pp schema_manager


describe "SchemaManager" do

  it "can find schemas by media_type" do
    schema = schema_manager.find :media_type => media_type("user")
    assert schema, "Couldn't find schema"
    assert_equal media_type("user"), schema[:mediaType]
    assert_equal "urn:gh-knockoff#user", schema[:id]
    assert schema[:properties], "Schema is missing properties"
  end


  it "can find schemas by JSON reference" do
    jsck = JSCK.new(api.schemas)

    ref = "urn:gh-knockoff#/definitions/repository_list/items/properties/refs"
    schema = jsck.resolve(ref)
    assert_equal schema[:type], "object"
    assert_equal schema[:properties].keys.sort, [:branches, :main, :tags]
  end

end



