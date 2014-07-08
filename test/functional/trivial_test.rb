# This test assumes you are running the Patchboard Trivial example in
# another terminal:
#
#   cd ../
#   git clone git@github.com:automatthew/patchboard-examples.git
#   cd patchboard-examples/trivial
#   bin/server.coffee test/data/questions.json
#

require_relative "setup"

module PatchboardTests; end

Client = Patchboard.discover "http://localhost:1979/", :namespace => PatchboardTests

user = Client.resources.users.create(:login => "foo-#{rand(100000)}")

describe "Using the Trivia Game API" do


  describe "A user resource created with resources.users" do

    it "has correct type" do
      assert_kind_of PatchboardTests::User, user
    end

    it "has expected actions" do
      assert_respond_to user, :get
      assert_respond_to user, :delete
    end

    describe "A question asked" do
      let(:question) do
        user.questions(:category => "Science").ask()
      end

      it "has correct type" do
        assert_kind_of PatchboardTests::Question, question
      end

      it "has expected actions" do
        assert_respond_to question, :answer
      end

      it "can be answered" do
        result = question.answer(:letter => "d")
        assert_equal true, result.success
        assert_equal "d", result.correct
      end
    end

  end


end

