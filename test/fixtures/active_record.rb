require 'active_record'
require 'jsonapi/resource_controller'
require 'jsonapi/resource'
require 'jsonapi/exceptions'
require 'rails'
require 'rails/all'

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable 'preferences'
end

### DATABASE
ActiveRecord::Schema.define do
  create_table :people, force: true do |t|
    t.string     :name
    t.string     :email
    t.datetime   :date_joined
    t.belongs_to :preferences
    t.timestamps
  end

  create_table :posts, force: true do |t|
    t.string     :title
    t.text       :body
    t.integer    :author_id
    t.belongs_to :section, index: true
    t.timestamps
  end

  create_table :comments, force: true do |t|
    t.text       :body
    t.belongs_to :post, index: true
    t.integer    :author_id
    t.timestamps
  end

  create_table :tags, force: true do |t|
    t.string :name
  end

  create_table :sections, force: true do |t|
    t.string :name
  end

  create_table :posts_tags, force: true do |t|
    t.references :post, :tag, index: true
  end
  add_index :posts_tags, [:post_id, :tag_id], unique: true

  create_table :comments_tags, force: true do |t|
    t.references :comment, :tag, index: true
  end

  create_table :iso_currencies, id: false, force: true do |t|
    t.string :code, limit: 3, null: false
    t.string :name
    t.string :country_name
    t.string :minor_unit
    t.timestamps
  end
  add_index :iso_currencies, :code, unique: true

  create_table :expense_entries, force: true do |t|
    t.string :currency_code, limit: 3, null: false
    t.integer :employee_id, null: false
    t.decimal :cost, precision: 12, scale: 4, null: false
    t.date :transaction_date
  end

  create_table :planets, force: true do |t|
    t.string :name
    t.string :description
    t.integer :planet_type_id
  end

  create_table :planets_tags, force: true do |t|
    t.references :planet, :tag, index: true
  end
  add_index :planets_tags, [:planet_id, :tag_id], unique: true

  create_table :planet_types, force: true do |t|
    t.string :name
  end

  create_table :moons, force: true do |t|
    t.string  :name
    t.string  :description
    t.integer :planet_id
  end

  create_table :preferences, force: true do |t|
    t.integer :person_id
    t.boolean :advanced_mode, default: false
  end

  create_table :facts, force: true do |t|
    t.integer  :person_id
    t.string   :spouse_name
    t.text     :bio
    t.float    :quality_rating
    t.decimal  :salary, :precision => 12, :scale => 2
    t.datetime :date_time_joined
    t.date     :birthday
    t.time     :bedtime
    t.binary   :photo, limit: 1.kilobyte
    t.boolean  :cool
  end

  create_table :books, force: true do |t|
    t.string :title
    t.string :isbn
  end
end

### MODELS
class Person < ActiveRecord::Base
  has_many :posts, foreign_key: 'author_id'
  has_many :comments, foreign_key: 'author_id'
  has_many :expense_entries, foreign_key: 'employee_id', dependent: :restrict_with_exception
  belongs_to :preferences

  ### Validations
  validates :name, presence: true
  validates :date_joined, presence: true
end

class Post < ActiveRecord::Base
  belongs_to :author, class_name: 'Person', foreign_key: 'author_id'
  belongs_to :writer, class_name: 'Person', foreign_key: 'author_id'
  has_many :comments
  has_and_belongs_to_many :tags, join_table: :posts_tags
  belongs_to :section

  validates :author, presence: true
  validates :title, length: { maximum: 35 }
end

class Comment < ActiveRecord::Base
  belongs_to :author, class_name: 'Person', foreign_key: 'author_id'
  belongs_to :post
  has_and_belongs_to_many :tags, join_table: :comments_tags
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :posts, join_table: :posts_tags
  has_and_belongs_to_many :planets, join_table: :planets_tags
end

class Section < ActiveRecord::Base
end

class IsoCurrency < ActiveRecord::Base
  self.primary_key = :code
  # has_many :expense_entries, foreign_key: 'currency_code'
end

class ExpenseEntry < ActiveRecord::Base
  belongs_to :employee, class_name: 'Person', foreign_key: 'employee_id'
  belongs_to :iso_currency, foreign_key: 'currency_code'
end

class Planet < ActiveRecord::Base
  has_many :moons
  belongs_to :planet_type

  has_and_belongs_to_many :tags, join_table: :planets_tags
end

class PlanetType < ActiveRecord::Base
  has_many :planets
end

class Moon < ActiveRecord::Base
  belongs_to :planet
end

class Preferences < ActiveRecord::Base
  has_one :author, class_name: 'Person'
  has_many :friends, class_name: 'Person'
end

class Fact < ActiveRecord::Base
end

class Like < ActiveRecord::Base
end

class Breed

  def initialize(id = nil, name = nil)
    if id.nil?
      @id = $breed_data.new_id
      $breed_data.add(self)
    else
      @id = id
    end
    @name = name
  end

  attr_accessor :id, :name

  def destroy
    $breed_data.remove(@id)
  end

  def save!
  end
end

class Book < ActiveRecord::Base
end

class BreedData
  def initialize
    @breeds = {}
  end

  def breeds
    @breeds
  end

  def new_id
    @breeds.keys.max + 1
  end

  def add(breed)
    @breeds[breed.id] = breed
  end

  def remove(id)
    @breeds.delete(id)
  end

end

### PORO Data - don't do this in a production app
$breed_data = BreedData.new
$breed_data.add(Breed.new(0, 'persian'))
$breed_data.add(Breed.new(1, 'siamese'))
$breed_data.add(Breed.new(2, 'sphinx'))
$breed_data.add(Breed.new(3, 'to_delete'))

### CONTROLLERS
class AuthorsController < JSONAPI::ResourceController

end

class PeopleController < JSONAPI::ResourceController

end

class PostsController < JSONAPI::ResourceController
end

class TagsController < JSONAPI::ResourceController
end

class IsoCurrenciesController < JSONAPI::ResourceController
end

class ExpenseEntriesController < JSONAPI::ResourceController
end

class BreedsController < JSONAPI::ResourceController
end

class FactsController < JSONAPI::ResourceController
end

### CONTROLLERS
module Api
  module V1
    class AuthorsController < JSONAPI::ResourceController
    end

    class PeopleController < JSONAPI::ResourceController
    end

    class PostsController < JSONAPI::ResourceController
    end

    class TagsController < JSONAPI::ResourceController
    end

    class IsoCurrenciesController < JSONAPI::ResourceController
    end

    class ExpenseEntriesController < JSONAPI::ResourceController
    end

    class BreedsController < JSONAPI::ResourceController
    end

    class PlanetsController < JSONAPI::ResourceController
    end

    class PlanetTypesController < JSONAPI::ResourceController
    end

    class MoonsController < JSONAPI::ResourceController
    end

    class LikesController < JSONAPI::ResourceController
    end
  end

  module V2
    class AuthorsController < JSONAPI::ResourceController
    end

    class PeopleController < JSONAPI::ResourceController
    end

    class PostsController < JSONAPI::ResourceController
    end

    class PreferencesController < JSONAPI::ResourceController
    end

    class BooksController < JSONAPI::ResourceController
    end
  end

  module V3
    class PostsController < JSONAPI::ResourceController
    end
  end

  module V4
    class PostsController < JSONAPI::ResourceController
    end

    class ExpenseEntriesController < JSONAPI::ResourceController
    end

    class IsoCurrenciesController < JSONAPI::ResourceController
    end
  end

  module V5
    class PostsController < JSONAPI::ResourceController
    end

    class ExpenseEntriesController < JSONAPI::ResourceController
    end

    class IsoCurrenciesController < JSONAPI::ResourceController
    end
  end
end

### RESOURCES
class PersonResource < JSONAPI::Resource
  attributes :id, :name, :email
  attribute :date_joined, format: :date_with_timezone

  has_many :comments
  has_many :posts

  filter :name

  def self.verify_custom_filter(filter, values, context)
    case filter
      when :name
        values.each do |value|
          if value.length < 3
            raise JSONAPI::Exceptions::InvalidFilterValue.new(filter, value)
          end
        end
    end
    return filter, values
  end
end

class AuthorResource < JSONAPI::Resource
  attributes :name, :email
  model_name 'Person'
  has_many :posts

  filter :name

  def self.find(filters, options = {})
    resources = []

    filters.each do |attr, filter|
      _model_class.where("\"#{attr}\" LIKE \"%#{filter[0]}%\"").each do |model|
        resources.push self.new(model, options[:context])
      end
    end
    return resources
  end

  def fetchable_fields
    super - [:email]
  end
end

class CommentResource < JSONAPI::Resource
  attributes :body
  has_one :post
  has_one :author, class_name: 'Person'
  has_many :tags
end

class TagResource < JSONAPI::Resource
  attributes :name

  has_many :posts
  # Not including the planets association so they don't get output
  #has_many :planets
end

class SectionResource < JSONAPI::Resource
  attributes 'name'
end

class PostResource < JSONAPI::Resource
  attribute :title
  attribute :body
  attribute :subject

  has_one :author, class_name: 'Person'
  has_one :section
  has_many :tags, acts_as_set: true
  has_many :comments, acts_as_set: false

  before_save do
    msg = "Before save"
  end

  after_save do
    msg = "After save"
  end

  before_update do
    msg = "Before update"
  end

  after_update do
    msg = "After update"
  end

  before_replace_fields do
    msg = "Before replace_fields"
  end

  after_replace_fields do
    msg = "After replace_fields"
  end

  around_update :around_update_check

  def around_update_check
    # do nothing
    yield
    # do nothing
  end

  def subject
    @model.title
  end

  filters :title, :author, :tags, :comments
  filter :id

  def self.updateable_fields(context)
    super(context) - [:author, :subject]
  end

  def self.createable_fields(context)
    super(context) - [:subject]
  end

  def self.sortable_fields(context)
    super(context) - [:id]
  end

  def self.verify_custom_filter(filter, values, context = nil)
    case filter
      when :id
        verify_keys(values, context)
    end
    return filter, values
  end

  def self.is_num?(str)
    begin
      !!Integer(str)
    rescue ArgumentError, TypeError
      false
    end
  end

  def self.verify_key(key, context = nil)
    raise JSONAPI::Exceptions::InvalidFieldValue.new(:id, key) unless is_num?(key)
    raise JSONAPI::Exceptions::RecordNotFound.new(key) unless find_by_key(key, context: context)
    return key
  end
end

class IsoCurrencyResource < JSONAPI::Resource
  primary_key :code
  attributes :name, :country_name, :minor_unit

  filter :country_name
end

class ExpenseEntryResource < JSONAPI::Resource
  attributes :cost
  attribute :transaction_date, format: :date

  has_one :iso_currency, foreign_key: 'currency_code'
  has_one :employee, class_name: 'Person'
end

class BreedResource < JSONAPI::Resource
  attribute :id, format_misspelled: :does_not_exist
  attribute :name, format: :title

  # This is unneeded, just here for testing
  routing_options :param => :id

  def self.find(filters, options = {})
    breeds = []
    $breed_data.breeds.values.each do |breed|
      breeds.push(BreedResource.new(breed, options[:context]))
    end
    breeds
  end

  def self.find_by_key(id, options = {})
    BreedResource.new($breed_data.breeds[id.to_i], options[:context])
  end

  def self.find_by_keys(keys, options = {})
    keys.map { |key| self.find_by_key(key, options) }
  end
end

class PlanetResource < JSONAPI::Resource
  attribute :name
  attribute :description

  has_many :moons
  has_one :planet_type

  has_many :tags, acts_as_set: true
end

class PropertyResource < JSONAPI::Resource
  attributes :name

  has_many :planets
end

class PlanetTypeResource < JSONAPI::Resource
  attributes :name
  has_many :planets
end

class MoonResource < JSONAPI::Resource
  attribute :name
  attribute :description

  has_one :planet
end

class PreferencesResource < JSONAPI::Resource
  attribute :advanced_mode

  has_one :author, foreign_key: :person_id
  has_many :friends

  def self.find_by_key(key, options = {})
    new(Preferences.first)
  end
end

class FactResource < JSONAPI::Resource
  attribute :spouse_name
  attribute :bio
  attribute :quality_rating
  attribute :salary
  attribute :date_time_joined
  attribute :birthday
  attribute :bedtime
  attribute :photo
  attribute :cool
end

module Api
  module V1
    class WriterResource < JSONAPI::Resource
      attributes :name, :email
      model_name 'Person'
      has_many :posts

      filter :name
    end

    class LikeResource < JSONAPI::Resource
    end

    class PostResource < JSONAPI::Resource
      # V1 no longer supports tags and now calls author 'writer'
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

    AuthorResource = AuthorResource.dup
    PersonResource = PersonResource.dup
    CommentResource = CommentResource.dup
    TagResource = TagResource.dup
    SectionResource = SectionResource.dup
    IsoCurrencyResource = IsoCurrencyResource.dup
    ExpenseEntryResource = ExpenseEntryResource.dup
    BreedResource = BreedResource.dup
    PlanetResource = PlanetResource.dup
    PlanetTypeResource = PlanetTypeResource.dup
    MoonResource = MoonResource.dup
    PreferencesResource = PreferencesResource.dup
  end
end

module Api
  module V2
    PreferencesResource = PreferencesResource.dup
    AuthorResource = AuthorResource.dup
    PostResource = PostResource.dup

    class BookResource < JSONAPI::Resource
      attribute :title
      attribute :isbn
    end
  end
end

module Api
  module V3
    PostResource = PostResource.dup
    PreferencesResource = PreferencesResource.dup
  end
end

module Api
  module V4
    PostResource = PostResource.dup
    ExpenseEntryResource = ExpenseEntryResource.dup
    IsoCurrencyResource = IsoCurrencyResource.dup
  end
end

module Api
  module V5
    PostResource = PostResource.dup
    ExpenseEntryResource = ExpenseEntryResource.dup
    IsoCurrencyResource = IsoCurrencyResource.dup
  end
end

warn 'start testing Name Collisions'
# The name collisions only emmit warnings. Exceptions would change the flow of the tests

class LinksResource < JSONAPI::Resource

end

class BadlyNamedAttributesResource < JSONAPI::Resource
  attributes :type, :href, :links

  has_many :links
  has_one :href
  has_one :id
  has_many :types
end
warn 'end testing Name Collisions'

### DATA
javascript = Section.create(name: 'javascript')
ruby = Section.create(name: 'ruby')

a = Person.create(name: 'Joe Author',
                 email: 'joe@xyz.fake',
                 date_joined: DateTime.parse('2013-08-07 20:25:00 UTC +00:00'))

b = Person.create(name: 'Fred Reader',
                 email: 'fred@xyz.fake',
                 date_joined: DateTime.parse('2013-10-31 20:25:00 UTC +00:00'))

c = Person.create(name: 'Lazy Author',
                  email: 'lazy@xyz.fake',
                  date_joined: DateTime.parse('2013-10-31 21:25:00 UTC +00:00'))

d = Person.create(name: 'Tag Crazy Author',
                  email: 'taggy@xyz.fake',
                  date_joined: DateTime.parse('2013-11-30 4:20:00 UTC +00:00'))

short_tag = Tag.create(name: 'short')
whiny_tag = Tag.create(name: 'whiny')
grumpy_tag = Tag.create(name: 'grumpy')
happy_tag = Tag.create(name: 'happy')
jr_tag = Tag.create(name: 'JR')

silly_tag = Tag.create(name: 'silly')
sleepy_tag = Tag.create(name: 'sleepy')
goofy_tag = Tag.create(name: 'goofy')
wacky_tag = Tag.create(name: 'wacky')

# id:1
Post.create(title: 'New post',
              body:  'A body!!!',
              author_id: a.id).tap do |post|

  post.tags.concat short_tag, whiny_tag, grumpy_tag

  post.comments.create(body: 'what a dumb post', author_id: a.id, post_id: post.id).tap do |comment|
    comment.tags.concat whiny_tag, short_tag
  end

  post.comments.create(body: 'i liked it', author_id: b.id, post_id: post.id).tap do |comment|
    comment.tags.concat happy_tag, short_tag
  end
end

# id:2
Post.create(title: 'JR Solves your serialization woes!',
              body:  'Use JR',
              author_id: a.id,
              section: Section.create(name: 'ruby')).tap do |post|

  post.tags.concat jr_tag

  post.comments.create(body: 'Thanks man. Great post. But what is JR?', author_id: b.id, post_id: post.id).tap do |comment|
    comment.tags.concat jr_tag
  end
end

# id:3
Post.create(title: 'Update This Later',
            body:  'AAAA',
            author_id: c.id)

# id:4
Post.create(title: 'Delete This Later - Single',
            body:  'AAAA',
            author_id: c.id)

# id:5
Post.create(title: 'Delete This Later - Multiple1',
            body:  'AAAA',
            author_id: c.id)

# id:6
Post.create(title: 'Delete This Later - Multiple2',
            body:  'AAAA',
            author_id: c.id)

# id:7
Post.create(title: 'Delete This Later - Single2',
            body:  'AAAA',
            author_id: c.id)

# id:8
Post.create(title: 'Delete This Later - Multiple2-1',
            body:  'AAAA',
            author_id: c.id)

# id:9
Post.create(title: 'Delete This Later - Multiple2-2',
            body:  'AAAA',
            author_id: c.id)

# id:9
Post.create(title: 'Update This Later - Multiple',
            body:  'AAAA',
            author_id: c.id)

# id:10
Post.create(title: 'JR How To',
            body:  'Use JR to write API apps',
            author_id: a.id).tap do |post|
  post.tags.concat jr_tag
end

IsoCurrency.create(code: 'USD', name: 'United States Dollar', country_name: 'United States', minor_unit: 'cent')
IsoCurrency.create(code: 'EUR', name: 'Euro Member Countries', country_name: 'Euro Member Countries', minor_unit: 'cent')
IsoCurrency.create(code: 'CAD', name: 'Canadian dollar', country_name: 'Canada', minor_unit: 'cent')

ExpenseEntry.create(currency_code: 'USD',
               employee_id: c.id,
               cost: '12.05',
               transaction_date: Date.parse('2014-04-15'))

ExpenseEntry.create(currency_code: 'USD',
               employee_id: c.id,
               cost: '12.06',
               transaction_date: Date.parse('2014-04-15'))

# id:11
Post.create(title: 'Tagged up post 1',
            body:  'AAAA',
            author_id: d.id,
            tag_ids: [6,7,8,9]
            )

# id:12
Post.create(title: 'Tagged up post 2',
            body:  'BBBB',
            author_id: d.id,
            tag_ids: [6,7,8,9]
)

gas_giant = PlanetType.create(name: 'Gas Giant')
planetoid = PlanetType.create(name: 'Planetoid')
terrestrial = PlanetType.create(name: 'Terrestrial')
sulfuric = PlanetType.create(name: 'Sulfuric')
unknown = PlanetType.create(name: 'unknown')

saturn = Planet.create(name: 'Satern',
                       description: 'Saturn is the sixth planet from the Sun and the second largest planet in the Solar System, after Jupiter.',
                       planet_type_id: planetoid.id)
titan = Moon.create(name:'Titan', description: 'Best known of the Saturn moons.', planet_id: saturn.id)
pluto = Planet.create(name: 'Pluto', description: 'Pluto is the smallest planet.', planet_type_id: planetoid.id)
uranus = Planet.create(name: 'Uranus', description: 'Insert adolescent jokes here.', planet_type_id: gas_giant.id)
jupiter = Planet.create(name: 'Jupiter', description: 'A gas giant.', planet_type_id: gas_giant.id)
betax = Planet.create(name: 'Beta X', description: 'Newly discovered Planet X', planet_type_id: unknown.id)
betay = Planet.create(name: 'Beta X', description: 'Newly discovered Planet Y', planet_type_id: unknown.id)
betaz = Planet.create(name: 'Beta X', description: 'Newly discovered Planet Z', planet_type_id: unknown.id)
betaw = Planet.create(name: 'Beta W', description: 'Newly discovered Planet W')

preference = Preferences.create

fact = Fact.create(spouse_name: 'Jane Author',
                   bio: 'First man to run across Antartica.',
                   quality_rating: 23.89/45.6,
                   salary: BigDecimal('47000.56'),
                   date_time_joined: DateTime.parse('2013-08-07 20:25:00 UTC +00:00'),
                   birthday: Date.parse('1965-06-30'),
                   bedtime: Time.parse('2000-01-01 20:00:00 UTC +00:00'),
                   photo: "abc",
                   cool: false
)

for pos in 0..999
  Book.create(title: "Book #{pos}", isbn: "12345-#{pos}-67890")
end