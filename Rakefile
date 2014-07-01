#$:.unshift "/Users/matthew/projects/oss/starter/lib"
require "starter/tasks/gems"
require "starter/tasks/git"

task "test" => %w[ test:unit ]

task "test:unit" do
  FileList['./test/unit/*_test.rb'].each { |file| require file}
end

task "test:functional" do
  FileList['./test/functional/*_test.rb'].each { |file| require file}
end
