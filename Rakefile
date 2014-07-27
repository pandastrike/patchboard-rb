require "starter/tasks/gems"
require "starter/tasks/gems/release"
require "starter/tasks/git"

task "setup" => %w[ test_api ]

task "test" => %w[ test:unit ]

task "test:unit" => %w[ test_api ] do
  FileList['./test/unit/*_test.rb'].each { |file| require file}
end

task "test:functional" do
  FileList['./test/functional/*_test.rb'].each { |file| require file}
end

task "test_api" => %w[
  node_modules/patchboard-api/test_api.json
]

file "node_modules/patchboard-api/test_api.json" => "package.json" do |t|
  sh "npm install"
  touch t.name
end



