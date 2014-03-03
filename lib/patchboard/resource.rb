
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
          #define_method name do
            #@attrs[name]
          #end
        end
      end

      if schema && schema[:additionalProperties] != false
        define_method :method_missing do |name, *args, &block|
          if args.size == 0
            @attrs[name.to_sym]
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
          action.request @url, *args
        end
      end
    end

    def self.decorate(instance, attrs)
      if self.schema && (properties = self.schema[:properties])
        properties.each do |key, sub_schema|
          next unless (value = attrs[key])

          case sub_schema[:type]
          when "string", "number", "integer", "boolean"
            nil
          when "array"
            if item_schema = sub_schema[:items]
              if mapping = self.api.find_mapping(item_schema)
                value.each_with_index do |item, i|
                  value[i] = mapping.klass.new item
                end
              end
            end
          else
            if mapping = self.api.find_mapping(sub_schema)
              if mapping.query
                instance.define_singleton_method key do |params|
                  params[:url] = value[:url]
                  url = mapping.generate_url(params)
                  mapping.klass.new :url => url
                end
              else
                attrs[key] = mapping.klass.new value
              end
            end
          end
        end
      end
      attrs
    end


    def initialize(attrs={})
      @attrs = self.class.decorate self, attrs

      #@url = @attrs[:url] || self.class.generate_url(@attrs)
      @url = @attrs[:url]

    end

    def [](key)
      @attrs[key]
    end

    def []=(key, value)
      @attrs[key] = value
    end


    def curl
    end
  end

end
