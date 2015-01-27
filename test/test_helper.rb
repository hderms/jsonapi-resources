require 'simplecov'

# To run tests with coverage
# COVERAGE=true rake test
if ENV['COVERAGE']
  SimpleCov.start do
  end
end

require 'minitest/autorun'
require 'minitest/spec'
require 'rails/all'

require 'jsonapi/routing_ext'
require 'jsonapi/configuration'
require 'jsonapi/formatter'

require File.expand_path('../helpers/value_matchers', __FILE__)
require File.expand_path('../helpers/hash_helpers', __FILE__)
require File.expand_path('../helpers/functional_helpers', __FILE__)

Rails.env = 'test'

JSONAPI.configure do |config|
  config.json_key_format = :camelized_key
end

class TestApp < Rails::Application
  config.eager_load = false
  config.root = File.dirname(__FILE__)
  config.session_store :cookie_store, key: 'session'
  config.secret_key_base = 'secret'

  ActiveSupport::JSON::Encoding.encode_big_decimal_as_string = false

  #Raise errors on unsupported parameters
  config.action_controller.action_on_unpermitted_parameters = :raise
end

TestApp.initialize!

require File.expand_path('../fixtures/active_record', __FILE__)

TestApp.routes.draw do
  jsonapi_resources :authors
  jsonapi_resources :people
  jsonapi_resources :comments
  jsonapi_resources :tags
  jsonapi_resources :posts
  jsonapi_resources :sections
  jsonapi_resources :iso_currencies
  jsonapi_resources :expense_entries
  jsonapi_resources :breeds
  jsonapi_resources :planets
  jsonapi_resources :planet_types
  jsonapi_resources :moons
  jsonapi_resources :preferences
  jsonapi_resources :facts

  namespace :api do
    namespace :v1 do
      jsonapi_resources :authors
      jsonapi_resources :people
      jsonapi_resources :comments
      jsonapi_resources :tags
      jsonapi_resources :posts
      jsonapi_resources :sections
      jsonapi_resources :iso_currencies
      jsonapi_resources :expense_entries
      jsonapi_resources :breeds
      jsonapi_resources :planets
      jsonapi_resources :planet_types
      jsonapi_resources :moons
      jsonapi_resources :preferences
      jsonapi_resources :likes
    end

    namespace :v2 do
      jsonapi_resources :authors
      jsonapi_resources :posts
      jsonapi_resource :preferences
      jsonapi_resources :books
    end

    namespace :v3 do
      jsonapi_resource :preferences do
        # Intentionally empty block to skip association urls
      end

      jsonapi_resources :posts, except: [:destroy] do
        jsonapi_link :author, except: [:destroy]
        jsonapi_links :tags, only: [:show, :create]
      end
    end

    JSONAPI.configuration.route_format = :camelized_route
    namespace :v4 do
      jsonapi_resources :posts
      jsonapi_resources :expense_entries
      jsonapi_resources :iso_currencies
    end
    JSONAPI.configuration.route_format = :dasherized_route
    namespace :v5 do
      jsonapi_resources :posts
      jsonapi_resources :expense_entries
      jsonapi_resources :iso_currencies
    end
    JSONAPI.configuration.route_format = :underscored_route
  end
end

class MiniTest::Unit::TestCase
  include Helpers::HashHelpers
  include Helpers::ValueMatchers
  include Helpers::FunctionalHelpers
end

class ActiveSupport::TestCase
  setup do
    @routes = TestApp.routes
  end
end

class UpperCamelizedKeyFormatter < JSONAPI::KeyFormatter
  class << self
    def format(key)
      super.camelize(:upper)
    end

    def unformat(formatted_key)
      formatted_key.to_s.underscore.to_sym
    end
  end
end

class DateWithTimezoneValueFormatter < JSONAPI::ValueFormatter
  class << self
    def format(raw_value, context)
      raw_value.in_time_zone('Eastern Time (US & Canada)').to_s
    end
  end
end

class DateValueFormatter < JSONAPI::ValueFormatter
  class << self
    def format(raw_value, context)
      raw_value.strftime('%m/%d/%Y')
    end
  end
end

class TitleValueFormatter < JSONAPI::ValueFormatter
  class << self
    def format(raw_value, source)
      super(raw_value, source).titlecase
    end

    def unformat(value, context)
      value.to_s.downcase
    end
  end
end
