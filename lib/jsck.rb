module Util
  def self.symbolize_keys(hash)
    hash.inject({}) {|result, (key, value)|
      new_key = case key
      when String
        key.to_sym
      else
        key
      end

      new_value = case value
      when Hash
        symbolize_keys(value)
      when Array
        value.map { |v| v.is_a?(Hash) ? symbolize_keys(v) : v }
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
end

class JSCK

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

    schemas.each do |uri, schema|
      register(uri, schema)
    end

    @schemas.each do |uri, schema|
      schema.assemble
    end

  end

  def register(uri, document)
    schema = Top.new(self, document)
    @schemas[uri] = schema
    @schemas[""] = schema
  end

  def register_media_type(type, schema)
    @media_types[type] = schema
  end

  def register_id(id, schema)
    @ids[id] = schema
  end

  class Dict < Hash

    # NEXT: use Context instead of manager.
    # Allows tracking the JSON pointer path
    def initialize(manager, data)
      @manager = manager
      self.replace(Util.symbolize_keys(data))
      @uri = self[:id]
      @ids = {}
    end

    def assemble
      self.each do |key, data|
        next if [:id, :mediaType].include?(key)

        if data[:type] || data[:extends] || data[:$ref]
          schema = Schema.new(@manager, data)
          schema.assemble
          self[key] = schema
        else
          holder = Dict.new(@manager, data)
          holder.assemble
          self[key] = holder
        end
      end
    end

  end

  class Top < Dict

    def initialize(manager, data)
      super(manager, data)
      # `definitions` is the conventional place to put schemas,
      # so we'll define fragment IDs by default where they are
      # not explicitly specified.
      self[:definitions].each do |name, schema|
        # `definitions` is the conventional place to put schemas,
        # so we'll define fragment IDs by default where they are
        # not explicitly specified.
        id = schema[:id] || [@uri, name].join("")
        @manager.register_id(id, schema)
      end
    end

  end

  class Schema < Hash

    def initialize(manager, data)
      @manager = manager
      self.replace(Util.symbolize_keys(data))
      @uri = self[:id]
      @ids = {}
    end

    def assemble
      if media_type = self[:mediaType]
        @manager.register_media_type(media_type, self)
      end

      if ref = self[:$ref]
        self.replace(self.reference(ref))
      end

      if self[:extends]
        process_extends(self)
      end


      case self[:type]
      when "object"
      when "array"
      end
    end


  end

  def process_top(schema)
    base_uri = schema[:id].chomp("#")
    schema[:definitions].each do |name, definition|
      # `definitions` is the conventional place to put schemas,
      # so we'll define fragment IDs by default where they are
      # not explicitly specified.
      id = definition[:id] || [base_uri, name].join("#")
      self.process_schema(id, definition)
    end
  end

  def process_schema(id, schema)
    @ids[id] = schema
    if media_type = schema[:mediaType]
      @media_types[media_type] = schema
    end

    if ref = schema[:$ref]
      schema.replace(self.reference(ref))
    end

    if schema[:extends]
      process_extends(schema)
    end


    case schema[:type]
    when "object"
    when "array"
    end
  end

  def process_extends(schema)
    parent = schema.delete(:extends)
    if ref = parent[:$ref]
      parent = self.resolve(ref)
    end
    extend_schema(parent, schema)
  end

  def extend_schema(parent, child)
    parent.each do |key, value|
      unless [:mediaType].include?(key)
        child[key] ||= value
      end
    end
  end


  def self.http
    HTTP.with_headers "User-Agent" => "jsck-rb v0.1.0"
  end

  def each(*args, &block)
    @schemas.each(*args, &block)
  end


  def find_document(uri)
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

  def resolve(uri)
    ref = Reference.new(uri)

    if document = self.find_document(ref.base)
      if ref.pointer
        p = JsonPointer.new(
          document, ref.fragment, :symbolize_keys => true
        )
        if p.exists?
          p.value
        else
          raise "No value found for '#{ref.fragment}'"
        end
      elsif ref.id
        find_id(ref.base, ref.id)
      else
        document
      end
    else
      raise "No document found for '#{ref.base}'"
    end
  end

  class Reference

    attr_reader :base, :fragment, :pointer, :id

    def initialize(string)
      raise "Invalid JSON reference" unless string.index("#")
      @base, @fragment = string.split("#")
      if @fragment.index("/") == 0
        @pointer = @fragment
      else
        @id = @fragment
      end
    end

  end

end
