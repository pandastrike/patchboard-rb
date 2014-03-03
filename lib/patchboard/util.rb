class Patchboard
  module Util
    module_function

    def camel_case(arg)  
      arg.to_s.split('_').map do |word|
        "#{word.slice(/^\w/).upcase}#{word.slice(/^\w(\w+)/, 1)}"
      end.join
    end

  end
end
