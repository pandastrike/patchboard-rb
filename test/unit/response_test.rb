require_relative "setup"

#FIXME: write actual tests.
h = %q[Custom key="otp.fBvQqSSlsNzJbqZcHKsylg", smurf="blue", Basic realm="foo"]
pp Patchboard::Response::Headers.parse_www_auth(h)

