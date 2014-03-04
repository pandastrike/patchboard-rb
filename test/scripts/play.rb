require "pp"
require "http"
require "json"

require_relative "../../lib/patchboard"

client = Patchboard.discover "http://localhost:1979/"
resources = client.resources



users = resources.users
response = users.create :login => "foo-#{rand(100000)}"
user = response.resource
pp

questions = user.questions(:category => "Science")
response = questions.ask()
question = response.resource
pp question.question

result = question.answer(:letter => "d").resource
pp result.class
pp result.correct, result.success

exit


search = resources.user_search(:login => "monkey")
results = search.get


