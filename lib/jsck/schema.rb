class JSCK

  class Context
    # TODO: do we allow changing scope?

    attr_reader :manager, :pointer
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
        @manager.resolve_id "#{@scope}#{ref}"
      else
        # global
        @manager.resolve ref
      end
    end

    def register_id(*args)
      @manager.register_id(*args)
    end

    def register_name(*args)
      @manager.register_name(*args)
    end

    def register_media_type(*args)
      @manager.register_media_type(*args)
    end

    def child(token)
      Context.new(@manager, @scope, "#{@pointer}/#{token}")
    end

    def id(token)
      "#{@scope}#{token}"
    end

  end

  # Containers handle the objects within a JSON Schema that do not
  # themselves define schemas.
  class Container < Hash

    def initialize(context, data)
      # Hash.new's argument is not, as you might expect from Array.new,
      # a hash that will be set as the contained data.  Nope, it's an item
      # that will be used as the default value for key accesses.
      # Bless the stdlib; bless its little heart.
      self.replace(data)
      @context = context
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

  # Top level schema Container; expected to have a 'definitions' field.
  # Not expected to define any schema itself.
  class TopSchema < Container

    def initialize(manager, data)
      @manager = manager
      scope = data[:id]
      pointer = "#{scope}#"
      @context = Context.new(@manager, scope, pointer)

      super(@context, data)

      # `definitions` is the conventional place to put schemas,
      # so we'll define fragment IDs by default where they are
      # not explicitly specified.
      self[:definitions].each do |name, schema|
        # FIXME: this registers the Hashes, not the Schemas

        pointer = @context.child("definitions").child(name).pointer

        @context.register_id(@context.id("##{name}"), pointer)

        #@context.register_id(@context.id("##{name}"), schema)
        @context.register_name(name, schema)
      end
    end

  end


  class Schema < Hash

    attr_reader :parent
    def initialize(context, data)
      @context = context
      self.replace(data)
      id = self[:id]
      if id && id.index("#") == 0
        self[:id] = @context.id(id)
      end
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
        # FIXME: JSON Schema allows this value to be an array.
        parent = self.delete(:extends)
        if ref = parent[:$ref]
          unless parent = @context.resolve(ref)
            raise "Can't find schema to extend: '#{ref}'"
          end
        end
        # TODO consider accumulating lambdas to do this work lazily.
        extend_schema(parent, self)
        @parent = parent
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
          case child[key]
          when Hash
            value.each do |k, v|
              child[key][k] ||= v
            end
          else
            child[key] ||= value
          end
        end
      end
    end

  end


end


