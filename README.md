# JSONAPI::Resources [![Build Status](https://secure.travis-ci.org/cerebris/jsonapi-resources.png?branch=master)](http://travis-ci.org/cerebris/jsonapi-resources)

`JSONAPI::Resources`, or "JR", provides a framework for developing a server that complies with the [JSON API](http://jsonapi.org/) specification.

Like JSON API itself, JR's design is focused on the resources served by an API. JR needs little more than a definition of your resources, including their attributes and relationships, to make your server compliant with JSON API.

JR is designed to work with Rails, and provides custom routes, controllers, and serializers. JR's resources may be backed by ActiveRecord models or by custom objects.

## Demo App

We have a simple demo app, called [Peeps](https://github.com/cerebris/peeps), available to show how JR is used.

## Installation

Add JR to your application's `Gemfile`:

    gem 'jsonapi-resources'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jsonapi-resources

## Usage

### Resources

Resources define the public interface to your API. A resource defines which attributes are exposed, as well as relationships to other resources.

Resource definitions should by convention be placed in a directory under app named resources, `app/resources`. The class name should be the single underscored name of the model that backs the resource with `_resource.rb` appended. For example, a `Contact` model's resource should have a class named `ContactResource` defined in a file named `contact_resource.rb`.

#### JSONAPI::Resource

Resources must be derived from `JSONAPI::Resource`, or a class that is itself derived from `JSONAPI::Resource`.

For example:

```ruby
require 'jsonapi/resource'

class ContactResource < JSONAPI::Resource
end
```

#### Attributes

Any of a resource's attributes that are accessible must be explicitly declared. Single attributes can be declared using the `attribute` method, and multiple attributes can be declared with the `attributes` method on the resource class.

For example:

```ruby
require 'jsonapi/resource'

class ContactResource < JSONAPI::Resource
  attribute :id
  attribute :name_first
  attributes :name_last, :email, :twitter
end
```

This resource has 5 attributes: `:id`, `:name_first`, `:name_last`, `:email`, `:twitter`. By default these attributes must exist on the model that is handled by the resource.

A resource object wraps a Ruby object, usually an `ActiveModel` record, which is available as the `@model` variable. This allows a resource's methods to access the underlying model.

For example, a computed attribute for `full_name` could be defined as such:

```ruby
require 'jsonapi/resource'

class ContactResource < JSONAPI::Resource
  attributes :id, :name_first, :name_last, :email, :twitter
  attribute :full_name

  def full_name
    "#{@model.name_first}, #{@model.name_last}"
  end
end
```

##### Fetchable Attributes

By default all attributes are assumed to be fetchable. The list of fetchable attributes can be filtered by overriding the `fetchable_fields` method.

Here's an example that prevents guest users from seeing the `email` field:

```ruby
class AuthorResource < JSONAPI::Resource
  attributes :id, :name, :email
  model_name 'Person'
  has_many :posts

  def fetchable_fields
    if (context.current_user.guest)
      super(context) - [:email]
    else
      super(context)
    end
  end
end
```

Context flows through from the controller and can be used to control the attributes based on the current user (or other value).

##### Creatable and Updateable Attributes

By default all attributes are assumed to be updateable and creatable. To prevent some attributes from being accepted by the `update` or `create` methods, override the `self.updateable_fields` and `self.createable_fields` methods on a resource.

This example prevents `full_name` from being set:

```ruby
require 'jsonapi/resource'

class ContactResource < JSONAPI::Resource
  attributes :id, :name_first, :name_last, :full_name

  def full_name
    "#{@model.name_first}, #{@model.name_last}"
  end

  def self.updateable_fields(context)
    super - [:full_name]
  end

  def self.createable_fields(context)
    super - [:full_name]
  end
end
```

The `context` is not by default used by the `ResourceController`, but may be used if you override the controller methods. By using the context you have the option to determine the createable and updateable fields based on the user.

##### Sortable Attributes

JR supports [sorting primary resources by multiple sort criteria](http://jsonapi.org/format/#fetching-sorting).

By default all attributes are assumed to be sortable. To prevent some attributes from being sortable, override the `self.sortable_fields` method on a resource.

Here's an example that prevents sorting by post's `body`:

```ruby
class PostResource < JSONAPI::Resource
  attribute :id, :title, :body

  def self.sortable_fields(context)
    super(context) - [:body]
  end
end
```

##### Attribute Formatting

Attributes can have a `Format`. By default all attributes use the default formatter. If an attribute has the `format` option set the system will attempt to find a formatter based on this name. In the following example the `last_login_time` will be returned formatted to a certain time zone:

```ruby
class PersonResource < JSONAPI::Resource
  attributes :id, :name, :email
  attribute :last_login_time, format: :date_with_timezone
end
```

The system will lookup a value formatter named `DateWithTimezoneValueFormatter` and will use this when serializing and updating the attribute. See the [Value Formatters](#value-formatters) section for more details.

#### Primary Key

Resources are always represented using a key of `id`. If the underlying model does not use `id` as the primary key you can use the `primary_key` method to tell the resource which field on the model to use as the primary key. Note: this doesn't have to be the actual primary key of the model. For example you may wish to use integers internally and a different scheme publicly.

```ruby
class CurrencyResource < JSONAPI::Resource
  primary_key :code
  attributes :code, :name

  has_many :expense_entries
end

```

#### Model Name

The name of the underlying model is inferred from the Resource name. It can be overridden by use of the `model_name` method. For example:

```ruby
class AuthorResource < JSONAPI::Resource
  attributes :id, :name
  model_name 'Person'
  has_many :posts
end
```

#### Associations

Related resources need to be specified in the resource. These are declared with the `has_one` and the `has_many` methods.

Here's a simple example where a post has a single author and an author can have many posts:

```ruby
class PostResource < JSONAPI::Resource
  attribute :id, :title, :body

  has_one :author
end
```

And the corresponding author:

```ruby
class AuthorResource < JSONAPI::Resource
  attribute :id, :name

  has_many :posts
end
```

##### Options

The association methods support the following options:
 * `class_name` - a string specifying the underlying class for the related resource
 * `foreign_key` - the method on the resource used to fetch the related resource. Defaults to `<resource_name>_id` for has_one and `<resource_name>_ids` for has_many relationships.
 * `acts_as_set` - allows the entire set of related records to be replaced in one operation. Defaults to false if not set.

Examples:

```ruby
 class CommentResource < JSONAPI::Resource
  attributes :id, :body
  has_one :post
  has_one :author, class_name: 'Person'
  has_many :tags, acts_as_set: true
 end
```

```ruby
class ExpenseEntryResource < JSONAPI::Resource
  attributes :id, :cost, :transaction_date

  has_one :currency, class_name: 'Currency', foreign_key: 'currency_code'
  has_one :employee
end
```

#### Filters

Filters for locating objects of the resource type are specified in the resource definition. Single filters can be declared using the `filter` method, and multiple filters can be declared with the `filters` method on the
resource class.

For example:

```ruby
require 'jsonapi/resource'

class ContactResource < JSONAPI::Resource
  attributes :id, :name_first, :name_last, :email, :twitter

  filter :id
  filters :name_first, :name_last
end
```

##### Finders

Basic finding by filters is supported by resources. This is implemented in the `find`, `find_by_key` and `find_by_keys` finder methods. Currently this is implemented for `ActiveRecord` based resources. The finder methods rely on the `records` method to get an `Arel` relation. It is therefore possible to override `records` to affect the three find related methods.

###### Customizing base records for finder methods

If you need to change the base records on which `find`, `find_by_key` and `find_by_keys` operate, you can override the `records` method on the resource class.

For example to allow a user to only retrieve his own posts you can do the following:

```ruby
class PostResource < JSONAPI::Resource
  attribute :id, :title, :body

  def self.records(options = {})
    context = options[:context]
    context.current_user.posts
  end
end
```

###### Applying Filters

The `apply_filter` method is called to apply each filter to the `Arel` relation. You may override this method to gain control over how the filters are applied to the `Arel` relation.

This example shows how you can implement different approaches for different filters.

```ruby
def apply_filter(records, filter, value)
  case filter
    when :visibility
      records.where('users.publicly_visible = ?', value == :public)
    when :last_name, :first_name, :name
      if value.is_a?(Array)
        value.each do |val|
          records = records.where(_model_class.arel_table[filter].matches(val))
        end
        return records
      else
        records.where(_model_class.arel_table[filter].matches(value))
      end
    else
      return super(records, filter, value)
  end
end
```

###### Override finder methods

Finally if you have more complex requirements for finding you can override the `find`, `find_by_key` and `find_by_keys` methods on the resource class.

Here's an example that defers the `find` operation to a `current_user` set on the `context` option:

```ruby
class AuthorResource < JSONAPI::Resource
  attributes :id, :name
  model_name 'Person'
  has_many :posts

  filter :name

  def self.find(filters, options = {})
    context = options[:context]
    authors = context.current_user.find_authors(filters)

    return authors.map do |author|
      self.new(author)
    end
  end
end
```

#### Pagination

Pagination is performed using a `paginator`, which is a class responsible for parsing the `page` request parameters and applying the pagination logic to the results.

##### Default Paginator

The default paginator is set using `JSONAPI.configure`, for example:

```ruby
JSONAPI.configure do |config|
  # built in paginators are :none, :offset, :cursor, :paged
  self.default_paginator = :offset

  self.default_page_size = 10
  self.maximum_page_size = 20
end
```

The default is `:none`.

##### Paginator in the Resource

The `paginator` can be set in the `resource`, which will override the `default_paginator`. This is done using the `paginator` method:

```ruby
    class BookResource < JSONAPI::Resource
      attribute :title
      attribute :isbn

      paginator :offset
    end
```

##### Paginators

`JSONAPI::Resource` supports several pagination methods by default, and allows you to implement a custom system if the defaults do not meet your needs.

##### Paged Paginator

The `paged` `paginator` returns results based on pages of a fixed size. Valid `page` parameters are `number` and `size`. If `number` is omitted the first page is returned. If `size` is omitted the `default_page_size` from the configuration settings is used.

##### Offset Paginator

The `offset` `paginator` returns results based on an offset from the beginning of the resultset. Valid `page` parameters are `offset` and `limit`. If `offset` is omitted a value of 0 will be used. If `limit` is omitted the `default_page_size` from the configuration settings is used.

##### Custom Paginators

Custom `paginators` can be used. These should derive from `Paginator`. The `apply` method takes a `relation` and is expected to return a `relation`. The `initialize` method receives the parameters from the `page` request parameters. It is up to the paginator author to parse and validate these parameters.

 For example, here is a very simple single record at a time paginator:

 ```ruby
class SingleRecordPaginator < JSONAPI::Paginator
  def initialize(params)
    # param parsing and validation here
    @page = params.to_i
  end

  def apply(relation)
    relation.offset(@page).limit(1)
  end
end
 ```

#### Callbacks

`ActiveSupport::Callbacks` is used to provide callback functionality, so the behavior is very similar to what you may be used to from `ActiveRecord`.

For example, you might use a callback to perform authorization on your resource before an action.

```ruby
class BaseResource < JSONAPI::Resource
  before_create :authorize_create

  def authorize_create
    # ...
  end
end
```

The types of supported callbacks are:
- `before`
- `after`
- `around`

##### `JSONAPI::Resource` Callbacks

Callbacks can be defined for the following `JSONAPI::Resource` events:

- `:create`
- `:update`
- `:remove`
- `:save`
- `:create_has_many_link`
- `:replace_has_many_links`
- `:create_has_one_link`
- `:replace_has_one_link`
- `:remove_has_many_link`
- `:remove_has_one_link`
- `:replace_fields`

##### `JSONAPI::OperationsProcessor` Callbacks

Callbacks can also be defined for `JSONAPI::OperationsProcessor` events:
- `:operations`: The set of operations.
- `:operation`: The individual operations.

### Controllers

`JSONAPI::Resources` provides a class, `ResourceController`, that can be used as the base class for your controllers. `ResourceController` supports `index`, `show`, `create`, `update`, and `destroy` methods. Just deriving your controller from `ResourceController` will give you a fully functional controller.

For example:

```ruby
class PeopleController < JSONAPI::ResourceController

end
```

Of course you are free to extend this as needed and override action handlers or other methods.

The context that's used for serialization and resource configuration is set by the controller's `context` method.

For example:

```ruby
class ApplicationController < JSONAPI::ResourceController
  def context
    {current_user: current_user}
  end
end

# Specific resource controllers derive from ApplicationController
# and share its context
class PeopleController < ApplicationController

end
```

#### Namespaces

JSONAPI::Resources supports namespacing of controllers and resources. With namespacing you can version your API.

If you namespace your controller it will require a namespaced resource.

In the following example we have a `resource` that isn't namespaced, and one the has now been namespaced. There are slight differences between the two resources, as might be seen in a new version of an API:

```ruby
class PostResource < JSONAPI::Resource
  attribute :id
  attribute :title
  attribute :body
  attribute :subject

  has_one :author, class_name: 'Person'
  has_one :section
  has_many :tags, acts_as_set: true
  has_many :comments, acts_as_set: false
  def subject
    @model.title
  end

  filters :title, :author, :tags, :comments
  filter :id
end

...

module Api
  module V1
    class PostResource < JSONAPI::Resource
      # V1 replaces the non-namespaced resource
      # V1 no longer supports tags and now calls author 'writer'
      attribute :id
      attribute :title
      attribute :body
      attribute :subject

      has_one :writer, foreign_key: 'author_id'
      has_one :section
      has_many :comments, acts_as_set: false

      def subject
        @model.title
      end

      filters :writer
    end

    class WriterResource < JSONAPI::Resource
      attributes :id, :name, :email
      model_name 'Person'
      has_many :posts

      filter :name
    end
  end
end
```

The following controllers are used:

```ruby
class PostsController < JSONAPI::ResourceController
end

module Api
  module V1
    class PostsController < JSONAPI::ResourceController
    end
  end
end
```

You will also need to namespace your routes:

```ruby
Rails.application.routes.draw do

  jsonapi_resources :posts

  namespace :api do
    namespace :v1 do
      jsonapi_resources :posts
    end
  end
end
```

When a namespaced `resource` is used, any related `resources` must also be in the same namespace.

#### Error codes

Error codes are provided for each error object returned, based on the error. These errors are:

```ruby
module JSONAPI
  VALIDATION_ERROR = 100
  INVALID_RESOURCE = 101
  FILTER_NOT_ALLOWED = 102
  INVALID_FIELD_VALUE = 103
  INVALID_FIELD = 104
  PARAM_NOT_ALLOWED = 105
  PARAM_MISSING = 106
  INVALID_FILTER_VALUE = 107
  COUNT_MISMATCH = 108
  KEY_ORDER_MISMATCH = 109
  KEY_NOT_INCLUDED_IN_URL = 110
  INVALID_INCLUDE = 112
  RELATION_EXISTS = 113
  INVALID_SORT_PARAM = 114
  INVALID_LINKS_OBJECT = 115
  TYPE_MISMATCH = 116
  INVALID_PAGE_OBJECT = 117
  INVALID_PAGE_VALUE = 118
  RECORD_NOT_FOUND = 404
  LOCKED = 423
end
```

These codes can be customized in your app by creating an initializer to override any or all of the codes.

### Serializer

The `ResourceSerializer` can be used to serialize a resource into JSON API compliant JSON. `ResourceSerializer` must be
 initialized with the primary resource type it will be serializing. `ResourceSerializer` has a `serialize_to_hash`
 method that takes a resource instance or array of resource instances to serialize. For example:

```ruby
require 'jsonapi/resource_serializer'
post = Post.find(1)
JSONAPI::ResourceSerializer.new(PostResource).serialize_to_hash(PostResource.new(post))
```

This returns results like this:

```ruby
{
  posts: {
    id: 1,
    title: 'New post',
    body: 'A body!!!',
    links: {
      section: nil,
      author: 1,
      tags: [1,2,3],
      comments: [1,2]
    }
  }
}
```

#### serialize_to_hash method options

The `serialize_to_hash` method also takes some optional parameters:

##### `include`

An array of resources. Nested resources can be specified with dot notation.

  *Purpose*: determines which objects will be side loaded with the source objects in a linked section

  *Example*: ```include: ['comments','author','comments.tags','author.posts']```

##### `fields`

A hash of resource types and arrays of fields for each resource type.

  *Purpose*: determines which fields are serialized for a resource type. This encompasses both attributes and association ids in the links section for a resource. Fields are global for a resource type.

  *Example*: ```fields: { people: [:id, :email, :comments], posts: [:id, :title, :author], comments: [:id, :body, :post]}```

```ruby
post = Post.find(1)
JSONAPI::ResourceSerializer.new(PostResource).serialize_to_hash(
  PostResource.new(post),
  include: ['comments','author','comments.tags','author.posts'],
  fields: {
    people: [:id, :email, :comments],
    posts: [:id, :title, :author],
    tags: [:name],
    comments: [:id, :body, :post]
  }
)
```

##### `context`

Context data can be provided to the serializer, which passes it to each resource as it is inspected.

#### Routing

JR has a couple of helper methods available to assist you with setting up routes.

##### `jsonapi_resources`

Like `resources` in `ActionDispatch`, `jsonapi_resources` provides resourceful routes mapping between HTTP verbs and URLs and controller actions. This will also setup mappings for relationship URLs for a resource's associations. For example:

```ruby
require 'jsonapi/routing_ext'

Peeps::Application.routes.draw do
  jsonapi_resources :contacts
  jsonapi_resources :phone_numbers
end
```

gives the following routes

```
                     Prefix Verb   URI Pattern                                               Controller#Action
contact_links_phone_numbers GET    /contacts/:contact_id/links/phone_numbers(.:format)       contacts#show_association {:association=>"phone_numbers"}
                            POST   /contacts/:contact_id/links/phone_numbers(.:format)       contacts#create_association {:association=>"phone_numbers"}
                            DELETE /contacts/:contact_id/links/phone_numbers/:keys(.:format) contacts#destroy_association {:association=>"phone_numbers"}
                   contacts GET    /contacts(.:format)                                       contacts#index
                            POST   /contacts(.:format)                                       contacts#create
                new_contact GET    /contacts/new(.:format)                                   contacts#new
               edit_contact GET    /contacts/:id/edit(.:format)                              contacts#edit
                    contact GET    /contacts/:id(.:format)                                   contacts#show
                            PATCH  /contacts/:id(.:format)                                   contacts#update
                            PUT    /contacts/:id(.:format)                                   contacts#update
                            DELETE /contacts/:id(.:format)                                   contacts#destroy
 phone_number_links_contact GET    /phone_numbers/:phone_number_id/links/contact(.:format)   phone_numbers#show_association {:association=>"contact"}
                            POST   /phone_numbers/:phone_number_id/links/contact(.:format)   phone_numbers#create_association {:association=>"contact"}
                            DELETE /phone_numbers/:phone_number_id/links/contact(.:format)   phone_numbers#destroy_association {:association=>"contact"}
              phone_numbers GET    /phone_numbers(.:format)                                  phone_numbers#index
                            POST   /phone_numbers(.:format)                                  phone_numbers#create
           new_phone_number GET    /phone_numbers/new(.:format)                              phone_numbers#new
          edit_phone_number GET    /phone_numbers/:id/edit(.:format)                         phone_numbers#edit
               phone_number GET    /phone_numbers/:id(.:format)                              phone_numbers#show
                            PATCH  /phone_numbers/:id(.:format)                              phone_numbers#update
                            PUT    /phone_numbers/:id(.:format)                              phone_numbers#update
                            DELETE /phone_numbers/:id(.:format)                              phone_numbers#destroy
```

##### `jsonapi_resource`

Like `jsonapi_resources`, but for resources you lookup without an id.

##### `jsonapi_links`

You can control the relationship routes by passing a block into `jsonapi_resources` or `jsonapi_resource`. An empty block
will not create any relationship routes.

You can add relationship routes in with `jsonapi_links`, for example:

```ruby
Rails.application.routes.draw do
  jsonapi_resources :posts, except: [:destroy] do
    jsonapi_link :author, except: [:destroy]
    jsonapi_links :tags, only: [:show, :create]
  end
end
```

This will create relationship routes for author (show and create, but not destroy) and for tags (again show and create, but not destroy).

#### Formatting

JR by default uses some simple rules to format an attribute for serialization. Strings and Integers are output to JSON as is, and all other values have `.to_s` applied to them. This outputs something in all cases, but it is certainly not correct for every situation.

If you want to change the way an attribute is serialized you have a couple of ways. The simplest method is to create a getter method on the resource which overrides the attribute and apply the formatting there. For example:

```ruby
class PersonResource < JSONAPI::Resource
  attributes :id, :name, :email
  attribute :last_login_time

  def last_login_time
    @model.last_login_time.in_time_zone(@context[:current_user].time_zone).to_s
  end
end
```

This is simple to implement for a one off situation, but not for example if you want to apply the same formatting rules to all DateTime fields in your system. Another issue is the attribute on the resource will always return a formatted response, whether you want it or not.

##### Value Formatters

To overcome the above limitations JR uses Value Formatters. Value Formatters allow you to control the way values are handled for an attribute. The `format` can be set per attribute as it is declared in the resource. For example:

```ruby
class PersonResource < JSONAPI::Resource
  attributes :id, :name, :email
  attribute :last_login_time, format: :date_with_timezone
end
```

A Value formatter has a `format` and an `unformat` method. Here's the base ValueFormatter and DefaultValueFormatter for reference:

```ruby
module JSONAPI
  class ValueFormatter < Formatter
    class << self
      def format(raw_value, context)
        super(raw_value)
      end

      def unformat(value, context)
        super(value)
      end
      ...
    end
  end
end

class DefaultValueFormatter < JSONAPI::ValueFormatter
  class << self
    def format(raw_value, context)
      case raw_value
        when String, Integer
          return raw_value
        else
          return raw_value.to_s
      end
    end
  end
end
```

You can also create your own Value Formatter. Value Formatters must be named with the `format` name followed by `ValueFormatter`, i.e. `DateWithTimezoneValueFormatter` and derive from `JSONAPI::ValueFormatter`. It is recommended that you create a directory for your formatters, called `formatters`.

The `format` method is called by the `ResourceSerializer` as is serializing a resource. The format method takes the `raw_value`, and `context` parameters. `raw_value` is the value as read from the model, and `context` is the context of the current user/request. From this you can base the formatted version of the attribute current context.

The `unformat` method is called when processing the request. Each incoming attribute (except `links`) are run through the `unformat` method. The `unformat` method takes the `value`, and `context` parameters. `value` is the value as it comes in on the request, and `context` is the context of the current user/request. This allows you process the incoming value to alter its state before it is stored in the model. By default no processing is applied.

###### Use a Different Default Value Formatter

Another way to handle formatting is to set a different default value formatter. This will affect all attributes that do not have a `format` set. You can do this by overriding the `default_attribute_options` method for a resource (or a base resource for a system wide change).

```ruby
  def default_attribute_options
    {format: :my_default}
  end
```

and

```ruby
class MyDefaultValueFormatter < JSONAPI::ValueFormatter
  class << self
    def format(raw_value, context)
      case raw_value
        when String, Integer
          return raw_value
        when DateTime
          return raw_value.in_time_zone(context[:current_user].time_zone).to_s
        else
          return raw_value.to_s
      end
    end
  end
end
```

This way all DateTime values will be formatted to display in the specified timezone.

#### Key Format

JSONAPI is agnostic on the format of the keys used in the responses. By default JR uses underscored keys which match the attribute names used by Rails models.  This can be changed by specifying a different key formatter.

For example to use camel cased keys with an initial lowercase character (JSON's default) create an initializer and add the following:

```
JSONAPI.configure do |config|
  # built in key format options are :underscored_key, :camelized_key and :dasherized_key
  config.json_key_format = :camelized_key
end
```

This will cause the serializer to use the `CamelizedKeyFormatter`. Besides `UnderscoredKeyFormatter` and `CamelizedKeyFormatter` JR defines the `DasherizedKeyFormatter`. You can also create your own `KeyFormatter`, for example:

```ruby
class UpperCamelizedKeyFormatter < JSONAPI::KeyFormatter
  class << self
    def format(key)
      super.camelize(:upper)
    end
  end
end
```

You would specify this in `JSONAPI.configure` as `:upper_camelized`.

## Contributing

1. Fork it ( http://github.com/cerebris/jsonapi-resources/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Copyright 2014 Cerebris Corporation. MIT License (see LICENSE for details).
