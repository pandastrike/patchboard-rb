class Patchboard

  class Endpoints

    def initialize(api, klasses, generate_url)
      @api = api
      @klasses = klasses

      @api.mappings.each do |name, mapping|
        if klass = @klasses[name]
          if mapping[:template] || mapping[:query]
            # A mapping with a template or query property requires
            # additional input before it can express a usable URL.
            # Thus the endpoint method takes parameters and instantiates
            # a resource of the correct class.

            define_singleton_method name do |params={}|
              if params.is_a? String
                url = params
              else
                url = generate_url.call(mapping, params)
              end
              klass.new({:url => url})
            end
          elsif mapping[:path]
            # When a mapping has the 'path' property, all that is needed to
            # create a usable resource is the full URL.  Thus this endpoint
            # method returns an instantiated resource directly.
            define_singleton_method name do
              klass.new(:url => generate_url.call(mapping))
            end
          elsif mapping[:url]
            define_singleton_method name do
              klass.new(:url => mapping[:url])
            end
          else
            raise "Mapping '#{name}' is invalid"
          end
        else
          raise "No resource class for mapping '#{name}'"
        end
      end
    end
  end

end


