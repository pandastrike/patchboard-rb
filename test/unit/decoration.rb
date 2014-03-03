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
    @repo = mapping.klass.new(@data)
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
      assert @repo.attributes[:name]
      assert @repo.attributes[:owner]
      assert @repo.attributes[:refs]
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
      assert @owner.attributes[:login]
      assert @owner.attributes[:email]
    end

  end

  describe "items in an array" do
    
    before do
      @tags = @repo.refs[:tags]
    end

    it "is correct type" do
      @tags.each do |tag|
        assert_kind_of PatchboardTests::Tag, tag
      end
    end
   
    #it "has expected action methods" do
      #assert_respond_to @owner, :get
      #assert_respond_to @owner, :update
    #end

    #it "has expected attributes" do
      #assert @owner.attributes[:login]
      #assert @owner.attributes[:email]
    #end

  end

end




