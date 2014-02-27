class Patchboard
  class Response

    attr_reader :raw, :data
    def initialize(raw)
      @raw = raw
      if @raw.headers["Content-Type"]
        if @raw.headers["Content-Type"] =~ %r{json}
          @data = JSON.parse @raw.body
        end
      end
    end

    def method_missing(name, *args, &block)
      if @raw.respond_to? name
        @raw.send(name, *args, &block)
      else
        super
      end
    end

    def respond_to?(name, include_private=false)
      @raw.respond_to?(*args) || super
    end

  end
end

