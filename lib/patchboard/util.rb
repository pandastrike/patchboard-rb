class Patchboard
  module Util
    module_function

    def camel_case( string )  
      string.split('_').map do |word|
        "#{word.slice(/^\w/).upcase}#{word.slice(/^\w(\w+)/, 1)}"
      end.join
    end

  end
end
