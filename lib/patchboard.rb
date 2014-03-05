# Allows you to determine which methods are defined on a specific class
# or module
class Module
  def local_methods
    self.methods.select { |m| self.method(m).owner == self }
  end
  
  def local_instance_methods
    self.instance_methods.select { |m| self.instance_method(m).owner == self }
  end
end

gem "http"
gem "json"
gem "hashie"

require "http"
require "json"
require "hashie"

require_relative "patchboard/api"
require_relative "patchboard/util"
require_relative "patchboard/resource"
require_relative "patchboard/endpoints"
require_relative "patchboard/action"
require_relative "patchboard/schema_manager"

class Patchboard

  module Resources
    # This module exists to provide a default namespace for the classes
    # generated when reflecting on the API.  If Patchboard is instantiated
    # with the option :namespace => SomeModule, that module will be used
    # instead.
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

  attr_reader :api, :resources, :resource_classes, :http, :schema_manager

  def initialize(api, options={})
    @api = API.new(api)
    @options = options

    if options[:namespace]
      if options[:namespace].is_a? Module
        @namespace = options[:namespace]
      else
        raise "Namespace must be a Module"
      end
    end

    @resource_classes = {}
    @endpoint_classes = {}

    @schema_manager = SchemaManager.new(@api.schemas)

    @http = self.class.http
    self.create_classes()
    @resources = Endpoints.new(@api, @endpoint_classes)
  end

  def create_classes
    @api.mappings.each do |name, mapping|
      resource_name = mapping.resource.name.to_sym
      schema = @schema_manager.find :name => resource_name

      klass = @resource_classes[name] ||= begin
        resource_def = mapping.resource
        self.create_class(name, resource_def, schema, mapping)
      end
      @endpoint_classes[name] = klass
    end
  end

  def create_class(resource_name, definition, schema, mapping)
    patchboard = self

    mapping.klass = klass = Class.new(Resource) do |klass|
      self.assemble(patchboard, definition, schema, mapping)
    end

    if @namespace
      @namespace.const_set Util.camel_case(resource_name).to_sym, klass
    else
      Patchboard::Resources.const_set Util.camel_case(resource_name).to_sym, klass
    end
    klass
  end



end

