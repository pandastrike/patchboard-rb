require_relative "setup"
require "pp"
require "json"
require "patchboard"

def media_type(name)
  "application/vnd.gh-knockoff.#{name}+json"
end



Client = PatchboardTests.client

describe "Decoration of response data" do

  before do
    mapping = Client.api.mappings[:repository]
    @data = JSON.parse(File.read("test/data/dectest.json"), :symbolize_names => true)
    @repo = mapping.klass.new(context={}, @data)
  end

  describe "top level object" do

    it "is correct type" do
      assert_kind_of PatchboardTests::Repository, @repo
    end
   
    it "has expected action methods" do
      assert_respond_to @repo, :get
      assert_respond_to @repo, :update
      assert_respond_to @repo, :delete
    end

    it "has expected attributes" do
      [:name, :owner, :refs].each do |key|
        assert @repo.attributes[key], "Missing attribute #{key}"
        assert @repo.send(key), "Missing attribute #{key}"
      end
    end

    it "attributes are exposed via methods" do
      assert_respond_to @repo, :name
      assert_respond_to @repo, :owner
      assert_respond_to @repo, :refs
    end

  end

  describe "an object as a top level attribute" do
    
    before do
      @owner = @repo.owner
    end

    it "is correct type" do
      assert_kind_of PatchboardTests::User, @owner
    end
   
    it "has expected action methods" do
      assert_respond_to @owner, :get
      assert_respond_to @owner, :update
    end

    it "has expected attributes" do
      assert @owner.attributes[:login], "Missing :login"
      assert @owner.attributes[:email], "Missing :email"
    end

  end

  describe "items in an array" do
    
    before do
      @tags = @repo.refs.tags
    end

    it "have correct types" do
      @tags.each do |tag|
        assert_kind_of PatchboardTests::Tag, tag
      end
    end
   
    it "has expected action methods" do
      @tags.each do |tag|
        assert_respond_to tag, :get
        assert_respond_to tag, :delete
      end
    end

    it "has expected attributes" do
      @tags.each do |tag|
        assert tag.attributes[:name]
        assert tag.attributes[:commit]
        assert tag.attributes[:message]
      end
    end

  end

  describe "values in a dictionary" do
    before do
      @dict = @repo.refs.branches
    end

    it "have correct types" do
      assert_kind_of PatchboardTests::Branch, @dict.master
      assert_kind_of PatchboardTests::Branch, @dict.release
    end
   
    it "have expected action methods" do
      @dict.each do |name, branch|
        assert_respond_to branch, :get
        assert_respond_to branch, :delete
      end
    end

    it "have expected attributes" do
      @dict.each do |name, branch|
        assert branch.attributes[:name]
        assert branch.attributes[:commit]
        assert branch.attributes[:message]
      end
    end
  end

end




