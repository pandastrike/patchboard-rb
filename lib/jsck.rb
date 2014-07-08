require "json-pointer"
require_relative "jsck/schema"


# Implementing just enough of the JSON Schema logic to be able
# to resolve 'extends' and '$ref', and to use JSON References
# to find schemas.
class JSCK

  def self.symbolize(hash)
    hash.inject({}) {|result, (key, value)|
      new_key = case key
      when String
        key.to_sym
      else
        key
      end

      new_value = case value
      when Hash
        symbolize(value)
      when Array
        value.map { |v| v.is_a?(Hash) ? symbolize(v) : v }
      else
        value
      end

      result[new_key] = new_value
      result
    }
  end

  def self.stringify_keys(hash)
    hash.inject({}) {|result, (key, value)|
      new_key = case key
      when Symbol
        key.to_s
      else
        key
      end

      new_value = case value
      when Hash
        stringify_keys(value)
      when Array
        value.map { |v| v.is_a?(Hash) ? stringify_keys(v) : v }
      else
        value
      end

      result[new_key] = new_value
      result
    }
  end

  def self.http
    @http ||= HTTP.with_headers "User-Agent" => "jsck-rb v0.1.0"
  end

  attr_reader :schemas

  def initialize(schemas)
    @schemas = {}
    @media_types = {}
    @names = {}
    # for explicitly defined 'id' attributes.
    @ids = {}

    self.add(schemas)
  end

  def add(arg)
    case arg
    when Array
      schemas = {}
      arg.each do |schema|
        uri = schema[:id] || "urn:fake"
        schemas[uri] = schema
      end
    when Hash
      schemas = arg
    end

    # First record all the schema documents, so that cross references
    # can be resolved.
    schemas.each do |uri, schema|
      register(uri, schema)
    end

    # Then destructively convert the schema data structures into
    # smarter objects.

    @schemas.each do |uri, schema|
      schema.assemble
    end

  end

  def register(uri, document)
    schema = TopSchema.new(self, JSCK.symbolize(document))
    @schemas[uri] = schema
  end

  def register_media_type(type, schema)
    @media_types[type] = schema
  end

  def register_id(id, pointer)
    @ids[id] = pointer
  end

  def register_name(name, schema)
    @names[name] = schema
  end

  def find(options)
    if type = options[:mediaType] || options[:media_type]
      @media_types[type]
    #elsif ref = options[:ref]
      #@ids[ref]
    elsif name = options[:name]
      @names[name]
    else
      raise "Unusable argument to find: #{options}"
    end
  end

  def resolve(uri)
    raise "Invalid JSON Reference" unless uri.index("#")
    base, fragment = uri.split("#")

    if fragment.index("/") == 0 # It's a JSON Pointer
      resolve_pointer(base, fragment)
    else # It's an explicitly defined id.
      resolve_id(uri)
    end
  end

  def resolve_pointer(base, pointer)
    document = self.get_schema(base)
    raise "No document found for '#{base}'" unless document
    return document unless pointer

    p = JsonPointer.new(document, pointer, :symbolize_keys => true)
    raise "No value found for '#{pointer}'" unless p.exists?

    p.value
  end

  def resolve_id(uri)
    pointer = @ids[uri]
    resolve(pointer)
  end

  def get_schema(uri)
    if uri =~ /^https?:/
      @schemas[uri] ||= begin
        self.http_document(uri)
      rescue => error
        nil
      end
    else
      @schemas[uri]
    end
  end

  def http_document(uri)
    string = self.class.http.get(uri)
    JSON.parse(string, :symbolize_names => @symbolize)
  end


end

