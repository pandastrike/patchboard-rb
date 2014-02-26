class Patchboard

  class Action


    def initialize(patchboard, name, definition)
      @method = definition[:method]
      request, response = definition[:request], definition[:response]
      @status = response[:status] || 200

      headers = {
        "Accept" => media_type,
        "Content-Type" => media_type
      }
      @http = @patchboard.http.with_headers(headers)
    end

    def request(url, *args)
      @http.request @method, options
    end

    def prepare(url, *args)
      options = self.process_args(args)
    end

    def process_args(args)
    end


    #def initialize(client, name, definition)
      #@client = client
      #@schema_manager = @client.schema_manager
      #@name = name
      #@definition = definition

      #request = @definition[:request]
      #if request && (type = request[:type])
        #@request_schema = @schema_manager.find(:mediaType => type)
      #end

      #response = @definition[:response]
      #if response && (type = response[:type])
        #@response_schema = @schema_manager.find(:mediaType => type)
      #end
      #@_base_headers = self.base_headers
    #end


    #def base_headers
      #headers = {"User-Agent" => "patchboard-rb"}
      #if @request_schema
        #headers["Content-Type"] = @request_schema.mediaType
      #end
      #if @response_schema
        #headers["Accept"] = @response_schema.mediaType
      #end
      #headers
    #end

  end

end

