source "https://rubygems.org"

gem "rails", "~> 5.2.0"

gem "coffee-rails", "~> 4.2" # Rails 5.2 default
gem "jquery-rails"
gem "jquery-ui-rails"
gem "uglifier", ">= 1.3.0" # Rails 5.2 default

gem "sass-rails", "~> 5.0" # Rails 5.2 default

source "https://rails-assets.org" do
  gem "rails-assets-js-cookie"
  gem "rails-assets-mousetrap"
  gem "rails-assets-timeago"
  gem "rails-assets-MutationObserver"
end

gem "non-stupid-digest-assets"

# FIXME: remove version restriction once activerecord is updated to support pg 1.0+
gem "pg", "~> 0.18", :platforms => [:ruby, :mingw]
gem "activerecord-jdbcpostgresql-adapter", ">= 1.3.0", :platforms => :jruby

gem "diff-lcs"
gem "dalli"
gem "connection_pool"
gem "acts_as_versioned_rails3"
gem "geoip"
gem "exception_notification"
gem "will_paginate"
gem "will-paginate-i18n"
gem "sitemap_generator"
gem "daemons", :require => false
gem "newrelic_rpm"
gem "nokogiri"
gem "rails-i18n"
gem "addressable", :require => "addressable/uri"
gem "mini_magick"
gem "image_size"
gem "i18n-js", ">= 3.0.0.rc7"
gem "mini_mime"

group :standalone do
  platform :mri do
    gem "unicorn", :require => false
    gem "unicorn-worker-killer", :require => false
  end
  gem "puma", :platforms => [:jruby, :rbx, :mswin], :require => false
end

group :test do
  gem "rails-controller-testing"
end

gem "pry", :group => [:development, :test]

gem "jbuilder", "~> 2.5" # Rails 5.2 default

# Must be last.
gem "rack-mini-profiler", :group => :development

gem 'rmagick'
