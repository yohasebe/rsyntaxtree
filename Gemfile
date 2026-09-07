# frozen_string_literal: true

source "https://rubygems.org"

# json 3.0 dropped the create_additions keyword that red-colors still passes to
# JSON.load, and cairo loads red-colors on the way to pango — so a bundle that
# resolves to json 3.0 raises before a single line of this library runs. Nothing
# here asks for that keyword; the constraint holds the bundle together until
# red-colors is released against the new signature, and comes out when it is.
gem "json", "< 3.0"
gem "optimist"
gem "pango"
gem "parslet"
gem "rsvg2"

group :development, :test do
  gem "minitest"
  gem "nokogiri"
  gem "rake"
end
