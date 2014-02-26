require "pp"
class Patchboard

  class SchemaManager

    def initialize(*schemas)
      #@schemas = schemas
      #@media_types = {}
      #@ids = {}

      #self.register_references(@schemas)

      #schemas.each do |schema|
        #base_id = schema["id"]
        #if definitions = schema["definitions"]
          #definitions.each do |name, definition|
            #id = definition["id"] || [base_id.chomp("#"), name].join("#")
            #self.register_schema(id, definition)
          #end
        #end
      #end
    end

    def register(schema)
    end

    def register_schema(id, schema)
      schema["id"] = id
      @ids[id] = schema
      if type = schema["mediaType"]
        @media_types[type] = schema
      end
    end

    def find(options)
      if type = options[:mediaType]
        "foo"
      elsif ref = options[:ref]
        @ids[ref]
      else
        raise "Unusable argument to find: #{options}"
      end
    end

  end

end

