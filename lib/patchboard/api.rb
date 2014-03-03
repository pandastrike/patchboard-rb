require "hashie"

class Patchboard

  class API
    attr_reader :mappings, :resources, :schemas, :service_url

    def initialize(definition)

      @service_url = definition[:service_url]
      @resources = Hashie::Mash.new definition[:resources]
      @resources.each do |name, definition|
        definition.name = name
      end
      @schemas = definition[:schemas]

      @mappings = {}
      definition[:mappings].each do |name, mapping|
        @mappings[name] = Mapping.new(self, name, mapping)
      end
    end

    def find_mapping(schema)
      # TODO: stitch this into the actual schemas.
      # ex:  schema.mapping
      if id = (schema[:id] || schema[:$ref])
        name = id.split("#").last
        @mappings[name.to_sym]
      end
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

  class Mapping

    attr_accessor :klass
    attr_reader :name, :resource, :url, :path, :template, :query

    def initialize(api, name, definition)
      @api = api
      @name = name
      @definition = definition
      @resource = @definition[:resource]
      @query = @definition[:query]
      @url = @definition[:url]
      @path = @definition[:path]
      @template = @definition[:template]

      unless (resource_name = @definition[:resource])
        raise "Mapping does not specify 'resource'"
      end

      unless (@resource = @api.resources[resource_name.to_sym])
        raise "Mapping specifies a resource that is not defined"
      end

      unless (@definition[:url] || @definition[:path] || @definition[:template])
        raise "Mapping is missing any form of URL specification"
      end

    end

    def generate_url(params={})
      if @url
        base = @url
      elsif params[:url]
        base = params[:url]
      elsif @path
        if @api.service_url
          base = [@api.service_url, @path].join("/")
        else
          raise "Tried to generate url from path, but API did not define service_url"
        end
      elsif @template
        raise "Template mappings are not yet implemented in the client"
      end

      if @query
        parts = []
        keys = @query.keys.sort()
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

  end

end
