require File.expand_path('../../../test_helper', __FILE__)
require File.expand_path('../../../fixtures/active_record', __FILE__)

class RequestTest < ActionDispatch::IntegrationTest

  def test_get
    get '/posts'
    assert_equal 200, status
  end

  def test_get_underscored_key
    JSONAPI.configuration.json_key_format = :underscored_key
    get '/iso_currencies'
    assert_equal 200, status
    assert_equal 3, json_response['data'].size
  end

  def test_get_underscored_key_filtered
    JSONAPI.configuration.json_key_format = :underscored_key
    get '/iso_currencies?country_name=Canada'
    assert_equal 200, status
    assert_equal 1, json_response['data'].size
    assert_equal 'Canada', json_response['data'][0]['country_name']
  end

  def test_get_camelized_key_filtered
    JSONAPI.configuration.json_key_format = :camelized_key
    get '/iso_currencies?countryName=Canada'
    assert_equal 200, status
    assert_equal 1, json_response['data'].size
    assert_equal 'Canada', json_response['data'][0]['countryName']
  end

  def test_get_camelized_route_and_key_filtered
    get '/api/v4/isoCurrencies?countryName=Canada'
    assert_equal 200, status
    assert_equal 1, json_response['data'].size
    assert_equal 'Canada', json_response['data'][0]['countryName']
  end

  def test_get_camelized_route_and_links
    JSONAPI.configuration.json_key_format = :camelized_key
    get '/api/v4/expenseEntries/1/links/isoCurrency'
    assert_equal 200, status
    assert_equal 'USD', json_response['isoCurrency']
  end

  def test_put_single
    put '/posts/3',
        {
          'data' => {
            'type' => 'posts',
            'id' => '3',
            'title' => 'A great new Post',
            'links' => {
              'tags' => {type: 'tags', ids: [3, 4]}
            }
          }
        }
    assert_equal 200, status
  end

  def test_destroy_single
    delete '/posts/7'
    assert_equal 204, status
  end

  def test_destroy_multiple
    delete '/posts/8,9'
    assert_equal 204, status
  end
end
