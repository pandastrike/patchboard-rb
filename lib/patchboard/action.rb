class Patchboard

  class Action


    def initialize(patchboard, name, definition)
      @patchboard = patchboard
      @method = definition["method"]
      request, response = definition["request"], definition["response"]
      @status = response["status"] || 200

      headers = {
        #"Accept" => media_type,
        #"Content-Type" => media_type
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




  end

end

