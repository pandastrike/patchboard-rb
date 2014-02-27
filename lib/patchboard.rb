gem "http"
gem "json"

require "http"
require "json"

require_relative "patchboard/util"
require_relative "patchboard/api"
require_relative "patchboard/endpoints"
require_relative "patchboard/action"
require_relative "patchboard/schema_manager"

class Patchboard

  module Resources
    # This module exists to provide a namespace for the classes
    # generated when reflecting on the API.
  end

  class Resource

    def initialize(attrs={})
      @attrs = attrs
      @url = @attrs[:url] || self.class.generate_url(@attrs)
    end

    def [](key)
      @attrs[key]
    end

    def []=(key, value)
      @attrs[key] = value
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
      data = JSON.parse(response.body, :symbolize_names => true)
      self.new(data, options)
    rescue JSON::ParserError => error
      raise "Unparseable API description: #{error}"
    rescue Errno::ECONNREFUSED => error
      raise "Problem discovering API: #{error}"
    end
  end

  attr_reader :resources, :resource_classes, :http, :schema_manager

  def initialize(api, options={})
    @api = API.new(api)
    @options = options

    @resource_classes = {}
    @endpoint_classes = {}

    @schema_manager = SchemaManager.new(@api.schemas)

    @http = self.class.http
    self.create_classes()
    @resources = Endpoints.new(@api, @endpoint_classes, self.method(:generate_url))
  end

  def create_classes
    @api.mappings.each do |name, mapping|
      resource_name = mapping[:resource].to_sym
      next if !resource_name

      klass = @resource_classes[resource_name] ||= begin
        resource_def = @api.resources[resource_name]
        self.create_class(resource_name, resource_def, mapping)
      end
      @endpoint_classes[name] = klass
    end
  end

  def create_class(resource_name, definition, mapping=nil)
    patchboard = self
    foo = lambda do |params|
      self.generate_url(mapping, params)
    end

    klass = Class.new(Resource) do |klass|
      # TODO: define attr_readers for the known attributes.
      define_singleton_method :generate_url do |params|
        foo.call(params)
      end

      if mapping && mapping[:query]
        define_singleton_method :query do
          #mapping[:query]
        end
      end

      definition[:actions].each do |name, action|
        action = Action.new(patchboard, name, action)

        define_method name do |*args|
          action.request @url, *args
        end
      end

    end
    Patchboard::Resources.const_set Util.camel_case(resource_name.to_s).to_sym, klass
  end


  def generate_url(mapping, params={})
    if mapping[:url]
      base = mapping[:url]
    elsif path = mapping[:path]
      if @api.service_url
        base = [@api.service_url, path].join("/")
      else
        raise "Tried to generate url from path, but API did not define service_url"
      end
    elsif template = mapping[:template]
      raise "Template mappings are not yet implemented in the client"
    end

    if query = mapping[:query]
      parts = []
      keys = query.keys.sort()
      # TODO check query schema
      keys.each do |key|
        if string = (params[key.to_s] || params[key.to_sym])
          parts << "#{URI.escape(key.to_s)}=#{URI.escape(string)}"
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

  def decorate(schema, data)
    if schema[:id] && (name = schema[:id].split("#")[1])
      if klass = @resource_classes[name.to_sym]
        _data = data
        if klass.query
          data = lambda do |params|
            _data[:url] = klass.generate_url(params)
            klass.new(_data)
          end
        else
          data = klass.new(_data)
        end
      end
    end
    self._decorate(schema, data) || data
  end

  def _decorate(schema=nil, data=nil)
    return unless (schema && data)
    if ref = schema[:$ref]
      puts "following ref: #{ref}"
      ref_schema = @schema_manager.find :ref => ref
      self.decorate ref_schema, data
    else
      if schema[:type] == "array"
        if schema[:items]
          data.each_with_index do |item, i|
            if result = self.decorate(schema[:items], item)
              data[i] = result
            end
          end
        end
      else
        # not array, so figure out what
        case schema[:type]
        when "string", "number", "integer", "boolean"
          nil
        else
          schema[:properties].each do |key, value|
            if result = self.decorate(value, data[key.to_sym])
              data[key.to_sym] = result
            end
          end
          if addprop = schema[:additionalProperties]
            data.each do |key, value|
              unless schema[:properties] && schema[:properties][key.to_sym]
                data[key] = self.decorate(addprop, value)
              end
            end
          end
          data
        end
      end
    end
  end

end

