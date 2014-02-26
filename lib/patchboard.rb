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

  class API
    attr_reader :mappings, :resources, :schemas, :service_url

    def initialize(definition)
      @mappings = definition["mappings"]
      #pp @mappings
      @resources = definition["resources"]
      @schemas = definition["schemas"]
      @service_url = definition["service_url"]
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
    @endpoint_classes = {}

    #self.validate_api(api)
    @schema_manager = SchemaManager.new(@api.schemas)

    @http = self.class.http
    self.create_classes()
    @resources = Endpoints.new(@api, @endpoint_classes, self.method(:generate_url))
  end

  def create_classes
    @api.mappings.each do |name, mapping|
      # validation
      resource_name = mapping["resource"]
      next if !resource_name

      klass = @resource_classes[resource_name] ||= begin
        resource_def = @api.resources[resource_name]
        self.create_class(resource_name, resource_def, mapping)
      end
      @endpoint_classes[name] = klass
    end
  end

  def create_class(resource_name, definition, mapping=nil)
    foo = lambda do |params|
      self.generate_url(mapping, params)
    end

    klass = Class.new(Resource) do |klass|
      define_singleton_method :generate_url do |params|
        foo.call(params)
      end

      if mapping && mapping["query"]
        @query = mapping["query"]
      end

      definition["actions"].each do |name, action|
      end

    end
    Patchboard::Resources.const_set camel_case(resource_name).to_sym, klass
  end


  def generate_url(mapping, params={})
    if mapping["url"]
      base = mapping["url"]
    elsif path = mapping["path"]
      if @api.service_url
        base = [@api.service_url, path].join("/")
      else
        raise "Tried to generate url from path, but API did not define service_url"
      end
    elsif template = mapping["template"]
      raise "Template mappings are not yet implemented in the client"
    end

    if query = mapping["query"]
      parts = []
      keys = query.keys.sort()
      # TODO check query schema
      keys.each do |key|
        if string = (params[key.to_s] || params[key.to_sym])
          parts << "#{URI.escape(key)}=#{URI.escape(string)}"
        end
      end
      if parts.size > 0
        query_string = "?#{parts.join("&")}"
      else
        query_string = ""
      end
      [base, query_string].join()
    else
      base
    end
  end

  def decorate()
  end

  def _decorate()
  end

  class Endpoints

    def initialize(api, klasses, generate_url)
      @api = api
      @klasses = klasses

      @api.mappings.each do |name, mapping|
        if klass = @klasses[name]
          if mapping["template"] || mapping["query"]
            # A mapping with a template or query property requires
            # additional input before it can express a usable URL.
            # Thus the endpoint method takes parameters and instantiates
            # a resource of the correct class.

            define_singleton_method name do |params={}|
              if params.is_a? String
                url = params
              else
                url = generate_url.call(mapping, params)
              end
              klass.new({"url" => url})
            end
          elsif mapping["path"]
            # When a mapping has the 'path' property, all that is needed to
            # create a usable resource is the full URL.  Thus this endpoint
            # method returns an instantiated resource directly.
            define_singleton_method name do
              klass.new("url" => generate_url.call(mapping))
            end
          elsif mapping["url"]
            define_singleton_method name do
              klass.new("url" => mapping["url"])
            end
          else
            raise "Mapping '#{name}' is invalid"
          end
        else
          raise "No resource class for mapping '#{name}'"
        end
      end
    end
  end

  class Resource

    def initialize(attrs={})
      @attrs = attrs
      @url = @attrs["url"] || self.class.generate_url(@attrs)
    end

    def method_missing(name, *args)
      if args.size == 0
        @attrs[name.to_s]
      else
        super
      end
    end

    def curl
    end
  end


end

