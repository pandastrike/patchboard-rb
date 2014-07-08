class Patchboard
  module Util
    module_function

    def camel_case(arg)  
      arg.to_s.split('_').map do |word|
        "#{word.slice(/^\w/).upcase}#{word.slice(/^\w(\w+)/, 1)}"
      end.join
    end

    def symbolize(hash)
      hash.inject({}) {|result, (key, value)|
        new_key = case key
        when String
          key.to_sym
        else
          key
        end

        new_value = case value
        when Hash
          symbolize(value)
        when Array
          value.map { |v| v.is_a?(Hash) ? symbolize(v) : v }
        else
          value
        end

        result[new_key] = new_value
        result
      }
    end

  end
end
