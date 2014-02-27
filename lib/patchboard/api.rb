class Patchboard

  class API
    attr_reader :mappings, :resources, :schemas, :service_url

    def initialize(definition)
      # TODO: validation
      @mappings = definition[:mappings]
      @resources = definition[:resources]
      @schemas = definition[:schemas]
      @service_url = definition[:service_url]
    end
  end

end
