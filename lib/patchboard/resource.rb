
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

      if schema && schema[:properties]
        schema[:properties].each do |name, definition|
          define_method name do
            @attributes[name]
          end
        end
      end

      if schema && schema[:additionalProperties] != false
        define_method :method_missing do |name, *args, &block|
          if args.size == 0
            @attributes[name.to_sym]
          else
            super(name, *args, &block)
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
        context = instance.context
        properties.each do |key, sub_schema|
          next unless (value = attributes[key])

          if mapping = self.api.find_mapping(sub_schema)
            if mapping.query
              # TODO: find a way to define this at runtime, not once
              # for every instance.
              instance.define_singleton_method key do |params={}|
                params[:url] = value[:url]
                url = mapping.generate_url(params)
                mapping.klass.new context, :url => url
              end
            else
              attributes[key] = mapping.klass.new context, value
            end
          else
            attributes[key] = self.api.decorate(context, sub_schema, value)
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
