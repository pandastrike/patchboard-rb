require_relative "setup"

h = %q[Gem-OOB-OTP key="otp.fBvQqSSlsNzJbqZcHKsylg", smurf="blue", Basic realm="foo"]
pp Patchboard::Response::Headers.parse_www_auth(h)

