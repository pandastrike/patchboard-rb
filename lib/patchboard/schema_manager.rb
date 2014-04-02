require "pp"
class Patchboard

  class SchemaManager

    def initialize(schemas)
      @schemas = schemas
      @media_types = {}
      @ids = {}
      @names = {}

      @schemas.each do |schema|
        # TODO error checking for missing id
        base_id = schema[:id].chomp("#")
        schema[:definitions].each do |name, definition|
          # `definitions` is the conventional place to put schemas,
          # so we'll define fragment IDs by default where they are
          # not explicitly specified.
          id = definition[:id] || [base_id, name].join("#")
          self.register_schema(id, definition)
        end
      end
    end

    def register_schema(id, schema)
      # FIXME:  extensions and refs are not imported.
      schema[:id] = id
      @ids[id] = schema
      name = id.split("#")[1].to_sym
      @names[name] = schema
      if type = schema[:mediaType]
        @media_types[type] = schema
      end
    end

    def find(options)
      if type = options[:mediaType] || options[:media_type]
        @media_types[type]
      elsif ref = options[:ref]
        @ids[ref]
      elsif name = options[:name]
        @names[name]
      else
        raise "Unusable argument to find: #{options}"
      end
    end

  end

end

