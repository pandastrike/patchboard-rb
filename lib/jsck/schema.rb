class JSCK

  class Container < Hash

    def initialize(context, data)
      @context = context
      self.replace(data)
      @uri = self[:id]
      @ids = {}
    end

    def assemble
      self.each do |key, data|
        next if [:id, :mediaType].include?(key)

        if data[:type] || data[:extends] || data[:$ref]
          schema = Schema.new(@context.child(key), data)
          schema.assemble
          self[key] = schema
        else
          holder = Container.new(@context.child(key), data)
          holder.assemble
          self[key] = holder
        end
      end
    end

  end

  # Top level schema document; expected to have a 'definitions' field.
  # Not expected to define any schema itself.
  class Top < Container

    def initialize(manager, data)
      @manager = manager
      scope = data[:id]
      pointer = "#{data}/"
      @context = Context.new(@manager, scope, pointer)

      super(@context, data)
      # `definitions` is the conventional place to put schemas,
      # so we'll define fragment IDs by default where they are
      # not explicitly specified.
      self[:definitions].each do |name, schema|
        # `definitions` is the conventional place to put schemas,
        # so we'll define fragment IDs by default where they are
        # not explicitly specified.
        id = schema[:id] || [@uri, name].join("")
        @context.register_id(id, schema)
      end
    end

  end

  class Context
    # TODO: do we allow changing scope?

    def initialize(*args)
      @manager, @scope, @pointer = args
    end

    def resolve(ref)
      case ref
      when /^#\//
        # fragment with a JSON pointer
        @manager.resolve "#{@scope}#{ref}"
      when /^#[^\/]/
        # fragment with a defined id, not a JSON pointer
        @manager.find_id "#{@scope}#{ref}"
      else
        # global
        @manager.resolve ref
      end
    end

    def register_id(*args)
      @manager.register_id(*args)
    end

    def register_media_type(*args)
      @manager.register_media_type(*args)
    end

    def child(token)
      Context.new(@manager, @scope, "#{@pointer}/#{token}")
    end

  end

  class Schema < Hash

    def initialize(context, data)
      @context = context
      self.replace(data)
      @uri = self[:id]
      @ids = {}
    end

    def assemble
      if media_type = self[:mediaType]
        @context.register_media_type(media_type, self)
      end

      if ref = self[:$ref]
        self.replace(@context.resolve(ref))
        # When a schema has a $ref, no other attributes should be defined.
        return
      end

      if self[:extends]
        parent = self.delete(:extends)
        if ref = parent[:$ref]
          unless parent = @context.resolve(ref)
            raise "Can't find schema to extend: '#{ref}'"
          end
        end
        # TODO consider accumulating lambdas to do this work lazily.
        extend_schema(parent, self)
      end

      if properties = self[:properties]
        properties.each do |name, data|
          schema = Schema.new(@context.child(name), data)
          schema.assemble
          properties[name] = schema
        end
      end

      if data = self[:additionalProperties]
        schema = Schema.new(@context.child("additionalProperties"), data)
        schema.assemble
        self[:additionalProperties] = schema
      end

      case data = self[:items]
      when Hash
        schema = Schema.new(@context.child("items"), data)
        schema.assemble
        self[:items] = schema
      when Array
        raise NotImplementedError
      end

      #TODO self[:additionalItems]

    end

    def extend_schema(parent, child)
      parent.each do |key, value|
        unless [:mediaType].include?(key)
          # FIXME: this should be merging properties, items, etc.
          # look for deep merge helpers.
          child[key] ||= value
        end
      end
    end

  end


end


