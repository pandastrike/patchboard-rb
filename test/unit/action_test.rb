require_relative "../setup"
require "json"
require "patchboard/schema_manager"
require "patchboard/action"

def media_type(name)
  "application/vnd.gh-knockoff.#{name}+json"
end

api = PatchboardTests.api
schema_manager = Patchboard::SchemaManager.new(api.schemas)


MockClient = Struct.new(:schema_manager, :http, :api)
Resource = Struct.new(:context)
MockHTTP = Struct.new(:with_headers)
http = MockHTTP.new
client = MockClient.new schema_manager, http

describe "Patchboard::Action with request body required" do

  before do
    @action = Patchboard::Action.new client, :create, {
      :method => "POST",
      :request => {
        :type => media_type("user"),
      },
      :response => {
        :type => media_type("user"),
        :status => 201
      }
    }
  end

  it "initializes" do
    assert_equal "POST", @action.method
    assert_equal 201, @action.status
    assert_equal media_type("user"), @action.headers["Content-Type"]
    assert_equal media_type("user"), @action.headers["Accept"]
  end

  describe "processing input for requests" do
    before do
      @content = {:email => "x@y.com"}
    end

    it "raises an error when content is not supplied" do
      assert_raises RuntimeError do
        @action.process_args []
      end
    end

    it "accepts objects as content" do
      options = @action.process_args [ @content ]
      assert_kind_of String, options[:body]
      assert_equal @content.to_json, options[:body]
    end

    it "accepts strings as content" do
      options = @action.process_args [ @content.to_json ]
      assert options[:body].is_a? String
      assert_equal @content.to_json, options[:body]
    end
  end

  describe "preparing request options" do

    it "works" do
      url, content = "http://api.thingy.com/", {:email => "x@y.com"}
      options = @action.prepare_request(Resource.new, url, content)
      assert_equal "http://api.thingy.com/", options[:url]
      assert options[:headers]
      assert_equal media_type("user"), options[:headers]["Content-Type"]
      assert_equal media_type("user"), options[:headers]["Accept"]
      assert_equal content.to_json, options[:body]
    end

  end

end

describe "Patchboard::Action with no request body" do

  before do
    @action = Patchboard::Action.new client, :get, {
      :method => "GET",
      :response => {
        :type => media_type("user"),
        :status => 200
      }
    }
  end

  it "initializes" do
    assert_equal "GET", @action.method
    assert_equal 200, @action.status
    assert_equal media_type("user"), @action.headers["Accept"]
  end

  describe "processing input for requests" do

    it "raises an error when content is supplied" do
      assert_raises RuntimeError do
        @action.process_args [{:foo => "bar"}]
      end
    end

    it "is happy when no content is supplied" do
      options = @action.process_args [ ]
      assert_nil options[:body]
    end

  end

end
