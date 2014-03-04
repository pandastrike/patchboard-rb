# This test assumes you are running the Patchboard Trivial example in
# another terminal:
#
#   cd ../
#   git clone git@github.com:automatthew/patchboard-examples.git
#   cd patchboard-examples/trivial
#   bin/server.coffee test/data/questions.json
#

require "patchboard"

module PatchboardTests; end

Client = Patchboard.discover "http://localhost:1979/", :namespace => PatchboardTests


describe "Using the Trivia Game API" do

  before do
    @resources = Client.resources
    @users = @resources.users
  end

  describe "A user resource created with resources.users" do
    let(:user) do
      @users.create(:login => "foo-#{rand(100000)}").resource
    end

    it "has correct type" do
      assert_kind_of PatchboardTests::User, user
    end

    it "has expected actions" do
      assert_respond_to user, :get
      assert_respond_to user, :delete
    end

    describe "A question asked" do
      let(:question) do
        user.questions(:category => "Science").ask().resource
      end

      it "has correct type" do
        assert_kind_of PatchboardTests::Question, question
      end

      it "has expected actions" do
        assert_respond_to question, :answer
      end

      it "can be answered" do
        result = question.answer(:letter => "d").resource
        assert_equal true, result.success
        assert_equal "d", result.correct
      end
    end

  end


end

