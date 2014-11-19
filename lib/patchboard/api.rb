
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

    class ArrayResource < Array
      attr_accessor :response
    end

    class HashResource < Hash
      attr_accessor :response
    end

    def decorate(context, schema, data)
      unless schema
        return Hashie::Mash.new(data)
      end

      if mapping = self.find_mapping(schema)
        # when we have a resource class, instantiate it using the input data.
        data = mapping.klass.new context, data
      else
        # Otherwise traverse the schema in search of subschemas that have
        # resource classes available.

        if schema[:items]
          # TODO: handle the case where schema.items is an array, which
          # signifies a tuple.  schema.additionalItems then becomes important.
          array = data.map! do |item|
            self.decorate(context, schema[:items], item)
          end
          data = ArrayResource.new(array)
        end

        if schema[:properties]
          schema[:properties].each do |key, prop_schema|
            if value = data[key]
              data[key] = self.decorate(context, prop_schema, value)
            end
          end
        end

        if schema[:additionalProperties]
          data.each do |key, value|
            next if schema[:properties] && schema[:properties][key]
            data[key] = self.decorate(context, schema[:additionalProperties], value)
          end
        end

        if data.is_a? Hash
          data = Hashie::Mash.new data
        end
        data
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
            parts << "#{CGI::escape(key.to_s)}=#{CGI::escape(string)}"
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
