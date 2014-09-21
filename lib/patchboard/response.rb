class Patchboard
  class Response

    module Headers

      module_function

      ## This example Authorization value has two schemes:  Custom and Basic
      ## The Custom scheme has two params, key and smurf
      ## The Basic scheme has one param, realm
      # %q[Custom key="otp.fBvQqSSlsNzJbqZcHKsylg", smurf="blue", Basic realm="foo"]
      #
      # Char by char parsing? Would have to consider escape characters \" if
      # using a stateful counter.
      #
      # Token by token parsing, concatenating parameters that were split by spaces

      WWWAuthRegex = /
        # keys are not quoted
        ([^\s,]+)
        =

        # value might be quoted
        "?
          # the value currently may not contain whitespace
          ([^\s,"]+)
        "?
      /x # the x flag means whitespace within the Regex definition is ignored

      def parse_www_auth(string)
        parsed = {}
        # FIXME:  This assumes that no quoted strings have spaces within.
        tokens = string.split(" ")
        check_no_spaces tokens
        name = tokens.shift
        parsed[name] = {}
        # FIXME: flesh out no token error
        pp tokens
        check_no_tokens tokens
        while token = tokens.shift
          # Now I have two problems
          if md = WWWAuthRegex.match(token)
            full, key, value = md.to_a
            parsed[name][key] = value
          else
            name = token
            parsed[name] = {}
          end
        end
        parsed
      end

      def concat_params(tokens_array)
        parens_counter = 0
        concat_string = ""
        concat_array = []
        while current = tokens_array.shift
          #current = current.gsub(\\"\, '')
          # FIXME: find quote one at a time? or all at once?
          # How to detect param="value""""?
          # Correctly space delimited, even number of parens, no escape slash
          if found quote
            increment parens_counter
            concat_string = concat_string + current
          if parens_counter == 2
            parens_counter = 0
            concat_array.push current
            concat_string = ""
        end

        if parens_counters.odd?
          raise_auth_exception "odd number of parentheses"
        end
      end

      def raise_auth_exception(error)
        raise "invalid auth challenge syntax: #{error}"
      end

      def check_no_spaces(tokens)
        if tokens.length <= 1
          raise_auth_exception "challenge contains no spaces"
        end
      end

      def check_no_tokens(tokens)
        if tokens.length == 0
          raise_auth_exception "challenge contains no tokens"
        end
      end

    end


    attr_accessor :resource
    attr_reader :raw, :data, :parsed_headers
    def initialize(raw)
      @raw = raw
      if @raw.headers["Content-Type"]
        if @raw.headers["Content-Type"] =~ %r{application/.*json}
          @data = JSON.parse @raw.body, :symbolize_names => true
        end
      end
      @parsed_headers = {}
      parse_headers
    end

    def parse_headers
      @raw.headers.each do |name, string|
        case name
        when /www-authenticate/i
          @parsed_headers["WWW-Authenticate"] = Headers.parse_www_auth(string)
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

    def respond_to?(*args)
      @raw.respond_to?(*args) || super
    end

  end
end

