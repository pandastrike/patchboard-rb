
class Patchboard

  class Resource

    def self.assemble(patchboard, definition, schema, mapping)

      define_singleton_method(:api) do
        patchboard.api
      end

      define_singleton_method(:mapping) do
        mapping
      end

      define_singleton_method(:schema) do
        schema
      end

      # FIXME: break this out into multiple methods.
      if schema && schema[:properties]
        schema[:properties].each do |name, definition|

          if property_mapping = self.api.find_mapping(definition)
            if property_mapping.query
              define_method name do |params={}|
                params[:url] = @attributes[name][:url]
                url = property_mapping.generate_url(params)
                property_mapping.klass.new self.context, :url => url
              end
            else
              define_method name do
                property_mapping.klass.new self.context, @attributes[name]
              end
            end
          else
            define_method name do
              @attributes[name]
            end
          end

        end
      end


      # When an additionalProperties schema is defined, the resource can
      # contain top-level attributes that should obey that schema.
      if schema && schema[:additionalProperties] != false

        if (add_mapping = self.api.find_mapping(schema)) && (add_mapping.query)
          define_method :method_missing do |name, params|
            params[:url] = @attributes[name][:url]
            url = add_mapping.generate_url(params)
            add_mapping.klass.new self.context, :url => url
          end
        else
          define_method :method_missing do |name|
            @attributes[name.to_sym]
          end
        end
      end

      define_singleton_method :generate_url do |params|
        mapping.generate_url(params)
      end

      definition[:actions].each do |name, action|
        action = Action.new(patchboard, name, action)

        define_method name do |*args|
          action.request self, @url, *args
        end
      end
    end

    def self.decorate(instance, attributes)
      # TODO: non destructive decoration
      # TODO: add some sort of validation for the input attributes.
      # Hey, we have a JSON Schema, why not use it?
      if self.schema && (properties = self.schema[:properties])
        properties.each do |key, sub_schema|
          if (value = attributes[key]) && !self.api.find_mapping(sub_schema)
            attributes[key] = self.api.decorate(instance.context, sub_schema, value)
          end
        end
      end
      attributes
    end

    attr_accessor :response
    attr_reader :url, :context, :attributes

    def initialize(context, attributes={})
      @context = context
      @attributes = self.class.decorate self, Hashie::Mash.new(attributes)
      @url = @attributes[:url]
    end

    def inspect
      id = "%x" % (self.object_id << 1)
      %Q{
        #<#{self.class}:0x#{id}
        @url="#{@url}" @context=#{@context}>
      }.strip
    end

    def [](key)
      @attributes[key]
    end

    def []=(key, value)
      @attributes[key] = value
    end


    def curl
      raise "Unimplemented"
    end

    def values_at(*keys)
      self.attributes.values_at(*keys)
    end

    def to_hash
      self.attributes
    end

    def to_json(*a)
      self.to_hash.to_json(*a)
    end
  end

end
