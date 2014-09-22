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
        pp concat_params tokens
        check_no_spaces tokens
        name = tokens.shift
        parsed[name] = {}
        # FIXME: flesh out no token error
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
          has_quote = false
          current = current.gsub("\\\"", "")
          current.each_char do |c|
            # FIXME: if not preceded by = and not the last index throw eror
            # multiple occurences: param="="something", param="hello world""
            if c == "\""
              has_quote = true
              parens_counter += 1
            end 
          end

          ### test
          index_equal = current.index("=")
          index_first_quote = current.index("\"")
          
          # value=" the_monster_will="
          if index_equal > 0 && index_equal == index_first_quote + 1
            if found_start
              #raise_auth_exception "
            found_start = true
          end
          if current.last == "\""
            found_end = true
          end

          if parens_counter > 2
            raise_auth_exception "too many damn quotes"
          end

          ### test

          case 
            # no previous quotes, no current quotes
            when parens_counter == 0 && !has_quote
              concat_array.push current
            # previous quote, no current quote, continue concat
            when parens_counter == 1 && !has_quote
              concat_string = concat_string + current
            # previous quote, current quote, close concat
            when parens_counter == 2
              parens_counter = 0
              concat_array.push current
              concat_string = ""
            when parens_counter > 2
              raise_auth_exception "too many damn quotes"
          end

        end # while loop
        
        if parens_counters.odd?
          raise_auth_exception "odd number of quotes"
        end

        concat_array
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

