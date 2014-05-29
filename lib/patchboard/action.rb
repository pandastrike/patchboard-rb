require_relative "response"

class Patchboard

  class Action

    attr_reader :method, :headers, :status

    def initialize(patchboard, name, definition)
      @name = name
      @patchboard = patchboard
      @api = @patchboard.api
      @schema_manager = @patchboard.schema_manager
      @method = definition[:method]


      @headers = {
      }

      request, response = definition[:request], definition[:response]

      if request
        @auth_scheme = request[:authorization]
        if request[:type]
          @headers["Content-Type"] = request[:type]
          @request_schema = @schema_manager.find :media_type => request[:type]
        end
      end

      if response && response[:type]
        @headers["Accept"] = response[:type]
        @response_schema = @schema_manager.find :media_type => response[:type]
      end
      @status = response[:status] || 200
    end

    def http
      @http ||= @patchboard.http
    end

    def request(resource, url, *args)
      options = self.prepare_request(resource, url, *args)
      raw = self.http.request @method, url, options.merge(:response => :object)
      response = Response.new(raw)
      if response.status != @status
        # TODO: custom exception classes, express response body in such.
        raise "Unexpected response status: #{response.status} - #{response.body}"
      end
      out = @api.decorate(resource.context, @response_schema, response.data)
      out.response = response
      out
    end

    def prepare_request(resource, url, *args)
      context = resource.context
      headers = {}.merge(@headers)
      options = {
        :url => url, :method => @method, :headers => headers
      }

      if @auth_scheme && context.respond_to?(:authorizer)
        credential = context.authorizer(@auth_scheme, resource, @name)
        headers["Authorization"] = "#{@auth_scheme} #{credential}"
      end

      input_options = self.process_args(args)
      if input_options[:body]
        options[:body] = input_options[:body]
      end
      # This code looks forward to the time when we have figured out
      # how we want Patchboard clients to take extra arguments for
      # requests.  Leaving it here now to show why process_args returns a Hash,
      # not just the body.
      if input_options[:headers]
        options[:headers].merge!(input_options[:headers])
      end
      options
    end

    def process_args(args)
      options = {}
      signature = args.map {|arg| arg.class.to_s }.join(".")
      if @request_schema
        case signature
        when "String"
          options[:body] = args[0]
        when "Hash", "Array"
          options[:body] = args[0].to_json
        else
          raise "Invalid arguments for action: request content is required"
        end
      else
        case signature
        when ""
        else
          raise "Invalid arguments for action"
        end
      end
      options
    end




  end

end

