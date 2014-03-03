require "pp"
require "http"
require "json"

require_relative "../../lib/patchboard"
#def request(verb, uri, options = {})

client = Patchboard.discover "http://localhost:1979/"
#pp client.resource_classes
resources = client.resources
#pp resources



users = resources.users
response = users.create :login => "foo-#{rand(1000)}"
user = response.resource
pp

questions = user.questions(:category => "Science")
question = questions.ask().resource
pp question
result = question.answer(:letter => "d").resource
pp result

exit


search = resources.user_search(:login => "monkey")
results = search.get


