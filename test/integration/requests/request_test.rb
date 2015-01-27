require File.expand_path('../../../test_helper', __FILE__)
require File.expand_path('../../../fixtures/active_record', __FILE__)

class RequestTest < ActionDispatch::IntegrationTest

  def after_teardown
    JSONAPI.configuration.paginator = :none
  end

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

  def test_pagination_none
    JSONAPI.configuration.paginator = :none
    get '/api/v2/books'
    assert_equal 200, status
    assert_equal 1000, json_response['data'].size
  end

  def test_pagination_offset_style
    JSONAPI.configuration.paginator = :offset
    get '/api/v2/books'
    assert_equal 200, status
    assert_equal JSONAPI.configuration.default_page_size, json_response['data'].size
    assert_equal 'Book 0', json_response['data'][0]['title']
  end

  def test_pagination_offset_style_offset
    JSONAPI.configuration.paginator = :offset
    get '/api/v2/books?page[offset]=50'
    assert_equal 200, status
    assert_equal JSONAPI.configuration.default_page_size, json_response['data'].size
    assert_equal 'Book 50', json_response['data'][0]['title']
  end

  def test_pagination_offset_style_offset_limit
    JSONAPI.configuration.paginator = :offset
    get '/api/v2/books?page[offset]=50&page[limit]=20'
    assert_equal 200, status
    assert_equal 20, json_response['data'].size
    assert_equal 'Book 50', json_response['data'][0]['title']
  end

  def test_pagination_offset_bad_param
    JSONAPI.configuration.paginator = :offset
    get '/api/v2/books?page[irishsetter]=50&page[limit]=20'
    assert_equal 400, status
  end
end
