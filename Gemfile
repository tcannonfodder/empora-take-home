source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.1"

gem 'csv'
gem 'httpx'

group :development, :test do
  gem "debug"
  gem "rake", "~> 13.0"
  gem "rubocop", "~> 1.21"
end

group :test do
  gem "m"
  gem "minitest", "~> 5.0"
  gem "simplecov"
  gem "webmock"
  gem "mocha"
end
