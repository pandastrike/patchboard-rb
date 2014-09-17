require_relative "setup"

describe "Patchboard::Response::Headers" do

  describe "parse valid headers" do

    it "should be successful for 2 valid schemes" do
      h = %q[ Custom key="otp.fBvQqSSlsNzJbqZcHKsylg", smurf="blue", 
              Basic realm="foo"]
      res = Patchboard::Response::Headers.parse_www_auth(h)
      custom = res["Custom"]
      assert_equal "otp.fBvQqSSlsNzJbqZcHKsylg", custom["key"]
      assert_equal "blue", custom["smurf"]
      basic = res["Basic"]
      assert_equal "foo", basic["realm"]
    end

    it "should be successful for 1 valid schemes" do
      h = %q[Cup cow="moo"]
      res = Patchboard::Response::Headers.parse_www_auth(h)
      assert_equal "moo", res["Cup"]["cow"]
    end

    # FIXME
    it "should handle spaces in parameter value" do
      h = %q[Wilson island="tom hanks"]
      res = Patchboard::Response::Headers.parse_www_auth(h)
      assert_equal "tom hanks", res["Wilson"]["island"]
    end

    # FIXME
    it "should handle one escaped quotes in parameter value" do
      h = %q[Cheats shark="there is no \"cow level"]
      res = Patchboard::Response::Headers.parse_www_auth(h)
      pp res
      assert_equal "there is no \\ cow level", res["Cheats"]["shark"]
      # FIXME: how to get the string right
    end

    it "should handle parameter value of only quotes" do
      h = %q[Lamp door="    "]
      res = Patchboard::Response::Headers.parse_www_auth(h)
      assert_equal "    ", res["Lamp"]["door"]
    end

  end

  describe "parse invalid headers" do

    # FIXME
    it "should handle empty string" do
      h = %q[]
      res = Patchboard::Response::Headers.parse_www_auth(h)
      assert_equal ({nil => {}}), res
    end

    # FIXME
    it "should handle scheme without parameters " do
      h = %q[Thanatos]
      res = Patchboard::Response::Headers.parse_www_auth(h)
      assert_equal ({"Thanatos" => {}}), res
    end

    # FIXME
    it "should handle invalid challenge with no scheme" do
      h = %q[southamerica="brazil", northamerica="canada"]
      res = Patchboard::Response::Headers.parse_www_auth(h)
    end

    # FIXME
    it "should handle scheme with empty string parameter values" do
      h = %q[Amazon product=""]
      res = Patchboard::Response::Headers.parse_www_auth(h)
      assert_equal ({"Amazon" => {}}), res
    end

    # FIXME: ignores City schema, treats losangeles as a part of Street
    it "should handle lack of space delimiting new schema" do
      h = %q[Street lampson="avenue",City losangeles="metropolitan"]
      res = Patchboard::Response::Headers.parse_www_auth(h)
    end

    # FIXME
    it "should handle trailing comma after scheme" do
      h = %q[ Basketball atlanta="hawks", orlando="magic",
              Football, washington="redskins", sandiego="chargers"]
      res = Patchboard::Response::Headers.parse_www_auth(h)
      basketball = res["Basketball"]
      assert_equal "hawks",  basketball["atlanta"]
      assert_equal "magic", basketball["orlando"]
      football = res["Football"]
#      assert_equal "redskins", football["washington"]
#      assert_equal "chargers", football["sandiego"]
    end

  end

end
