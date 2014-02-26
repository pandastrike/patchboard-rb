gem "http"
gem "json"

require "http"
require "json"

require_relative "patchboard/action"
require_relative "patchboard/schema_manager"

def camel_case( string )  
  string.split('_').map do |word|
    "#{word.slice(/^\w/).upcase}#{word.slice(/^\w(\w+)/, 1)}"
  end.join
end

class Patchboard
  module Resources
  end

  class Endpoints

    def initialize(api, klasses)
      @api = api
      @klasses = klasses

      @api.mappings.each do |name, mapping|
        if klass = @klasses[name]
          if mapping["template"] || mapping["query"]
            lambda do |params={}|
              klass.new(nil, params)
            end
          elsif mapping["path"]
            klass.new(:url => self.generate_url(mapping))
          elsif mapping["url"]
            klass.new(:url => mapping["url"])
          else
            puts "Unexpected mapping", name, mapping
          end
        else
          raise "No resource class for mapping '#{name}'"
        end
      end
    end
  end

  class Resource
    def curl
    end
  end

  class API
    attr_reader :mappings, :resources, :schemas

    def initialize(definition)
      @mappings = definition["mappings"]
      @resources = definition["resources"]
      @schemas = definition["schemas"]
    end
  end


  def self.http
    @http ||= HTTP.with_headers "User-Agent" => "patchboard-rb v0.1.0"
  end

  def self.discover(url, options={})
    begin
      response = self.http.request "GET", url,
        :response => :object,
        :headers => {
          "Accept" => "application/json"
        }
      data = JSON.parse(response.body)
      self.new(data, options)
    rescue JSON::ParserError => error
      raise "Unparseable API description: #{error}"
    rescue Errno::ECONNREFUSED => error
      raise "Problem discovering API: #{error}"
    end
  end

  attr_reader :resources, :resource_classes

  def initialize(api, options={})
    @api = API.new(api)
    @options = options

    @resource_classes = {}

    #self.validate_api(api)
    @schema_manager = SchemaManager.new(@api.schemas)

    @http = self.class.http
    self.create_classes()
    @resources = Endpoints.new(@api, @resource_classes)
    #self.create_endpoints()
  end

  def create_classes
    @api.resources.each do |name, definition|
      @resource_classes[name] = self.create_class(name, definition)
    end

    @api.mappings.each do |name, mapping|
      # validation
      resource_name = mapping["resource_name"]
      next if !resource_name
      resource_def = @api.resources[resource_name]
      @resource_classes[name] = self.create_class(resource_name, resource_def, mapping)
    end
  end

  def create_class(resource_name, definition, mapping=nil)
    klass = Class.new(Resource) do |klass|
      if mapping && mapping["query"]
        @query = mapping["query"]
      end

      def initialize(data={}, params={})
      end

      definition["actions"].each do |name, action|
      end

    end
    Patchboard::Resources.const_set camel_case(resource_name).to_sym, klass
  end

  def create_endpoints
    @api.mappings.each do |name, mapping|
      if klass = @resource_classes[name]
        if mapping["template"] || mapping["query"]
          @resources[name] = lambda do |params={}|
            klass.new(nil, params)
          end
        elsif mapping["path"]
          @resources[name] = klass.new(:url => self.generate_url(mapping))
        elsif mapping["url"]
          @resources[name] = klass.new(:url => mapping["url"])
        else
          puts "Unexpected mapping", name, mapping
        end
      else
        raise "No resource class for mapping '#{name}'"
      end
    end
  end

  def generate_url
  end

  def decorate()
  end

  def _decorate()
  end


end

