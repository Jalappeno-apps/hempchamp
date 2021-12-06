source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.0'

gem 'dotenv'
gem 'rake', '~> 13.0.6'
gem 'rails', '~> 6.0.3', '>= 6.0.3.4'
gem 'pg'
gem 'puma', '~> 4.1'
gem 'sass-rails', '>= 6'
gem 'webpacker', '~> 5.4.3'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.7'
# gem 'spree', '~> 4.3'
# gem 'spree_backend', '~> 4.3'
# gem 'spree_auth_devise'
# gem 'spree_emails'

gem 'spree' # core and API
gem 'spree_backend' # Rails admin panel (optional)
gem 'spree_emails' # transactional emails (optional)
gem 'spree_sample' # dummy data like products, taxons, etc
gem 'spree_auth_devise', '~> 4.3' # Devise integration (optional)
gem 'spree_i18n', '~> 5.0' # translation files (optional) 
gem 'spree_frontend'
gem 'spree_gateway'

# gem 'spree_i18n', github: 'archetype2142/spree_i18n', branch: 'master'
gem 'bootsnap', '>= 1.4.2', require: false
# gem 'spree_analytics_trackers'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
