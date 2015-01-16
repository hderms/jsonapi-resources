require File.expand_path('../../../test_helper', __FILE__)
require File.expand_path('../../../fixtures/active_record', __FILE__)
require 'jsonapi-resources'
require 'json'

class SerializerTest < MiniTest::Unit::TestCase
  def setup
    @post = Post.find(1)
    @fred = Person.find_by(name: 'Fred Reader')

    @expense_entry = ExpenseEntry.find(1)

    JSONAPI.configuration.json_key_format = :camelized_key
  end

  def after_teardown
    JSONAPI.configuration.json_key_format = :underscored_key
  end

  def test_serializer

    assert_hash_equals(
      {
        data: {
          type: 'posts',
          id: '1',
          title: 'New post',
          body: 'A body!!!',
          subject: 'New post',
          links: {
            self: 'http://example.com/posts/1',
            section: {
              self: 'http://example.com/posts/1/links/section',
              resource: 'http://example.com/posts/1/section',
              type: 'sections',
              id: nil
            },
            author: {
              self: 'http://example.com/posts/1/links/author',
              resource: 'http://example.com/posts/1/author',
              type: 'people',
              id: '1'
            },
            tags: {
              self: 'http://example.com/posts/1/links/tags',
              resource: 'http://example.com/posts/1/tags'
            },
            comments: {
              self: 'http://example.com/posts/1/links/comments',
              resource: 'http://example.com/posts/1/comments'
            }
          }
        }
      },
      JSONAPI::ResourceSerializer.new(PostResource).serialize_to_hash(
        PostResource.new(@post),
        base_url: 'http://example.com'
      )
    )
  end

  def test_serializer_namespaced_resource
    assert_hash_equals(
      {
        data: {
          type: 'posts',
          id: '1',
          title: 'New post',
          body: 'A body!!!',
          subject: 'New post',
          links: {
            self: 'http://example.com/api/v1/posts/1',
            section: {
              self: 'http://example.com/api/v1/posts/1/links/section',
              resource: 'http://example.com/api/v1/posts/1/section',
              type: 'sections',
              id: nil
            },
            writer: {
              self: 'http://example.com/api/v1/posts/1/links/writer',
              resource: 'http://example.com/api/v1/posts/1/writer',
              type: 'writers',
              id: '1'
            },
            comments: {
              self: 'http://example.com/api/v1/posts/1/links/comments',
              resource: 'http://example.com/api/v1/posts/1/comments'
            }
          }
        }
      },
      JSONAPI::ResourceSerializer.new(Api::V1::PostResource).serialize_to_hash(
        Api::V1::PostResource.new(@post),
        base_url: 'http://example.com'
      )
    )
  end

  def test_serializer_limited_fieldset

    assert_hash_equals(
      {
        data: {
          type: 'posts',
          id: '1',
          title: 'New post',
          links: {
            self: '/posts/1',
            author: {
              self: '/posts/1/links/author',
              resource: '/posts/1/author',
              type: 'people',
              id: '1'
            }
          }
        }
      },
      JSONAPI::ResourceSerializer.new(PostResource).serialize_to_hash(
        PostResource.new(@post),
        fields: {posts: [:id, :title, :author]}))
  end

  def test_serializer_include

    assert_hash_equals(
      {
        data: {
          type: 'posts',
          id: '1',
          title: 'New post',
          body: 'A body!!!',
          subject: 'New post',
          links: {
            self: '/posts/1',
            section: {
              self: '/posts/1/links/section',
              resource: '/posts/1/section',
              type: 'sections',
              id: nil
            },
            author: {
              self: '/posts/1/links/author',
              resource: '/posts/1/author',
              type: 'people',
              id: '1'
            },
            tags: {
              self: '/posts/1/links/tags',
              resource: '/posts/1/tags'
            },
            comments: {
              self: '/posts/1/links/comments',
              resource: '/posts/1/comments'
            }
          }
        },
        linked: [
          {
            type: 'people',
            id: '1',
            name: 'Joe Author',
            email: 'joe@xyz.fake',
            dateJoined: '2013-08-07 16:25:00 -0400',
            links: {
             self: '/people/1',
             comments: {
               self: '/people/1/links/comments',
               resource: '/people/1/comments'
             },
             posts: {
               self: '/people/1/links/posts',
               resource: '/people/1/posts'
             }
            }
          }
        ]
      },
      JSONAPI::ResourceSerializer.new(PostResource).serialize_to_hash(
        PostResource.new(@post), include: [:author]))
  end

  def test_serializer_key_format

    assert_hash_equals(
      {
        data: {
          type: 'posts',
          id: '1',
          title: 'New post',
          body: 'A body!!!',
          subject: 'New post',
          links: {
            self: '/posts/1',
            section: {
              self: '/posts/1/links/section',
              resource: '/posts/1/section',
              type: 'sections',
              id: nil
            },
            author: {
              self: '/posts/1/links/author',
              resource: '/posts/1/author',
              type: 'people',
              id: '1'
            },
            tags: {
              self: '/posts/1/links/tags',
              resource: '/posts/1/tags'
            },
            comments: {
              self: '/posts/1/links/comments',
              resource: '/posts/1/comments'
            }
          }
        },
        linked: [
          {
            type: 'people',
            id: '1',
            name: 'Joe Author',
            email: 'joe@xyz.fake',
            date_joined: '2013-08-07 16:25:00 -0400',
            links: {
              self: '/people/1',
              comments: {
                self: '/people/1/links/comments',
                resource: '/people/1/comments'
              },
              posts: {
                self: '/people/1/links/posts',
                resource: '/people/1/posts'
              }
            }
          }
        ]
      },
      JSONAPI::ResourceSerializer.new(PostResource).serialize_to_hash(
        PostResource.new(@post),
        include: [:author],
        key_formatter: UnderscoredKeyFormatter))
  end

  def test_serializer_include_sub_objects

    assert_hash_equals(
      {
        data: {
          type: 'posts',
          id: '1',
          title: 'New post',
          body: 'A body!!!',
          subject: 'New post',
          links: {
            self: '/posts/1',
            section: {
              self: '/posts/1/links/section',
              resource: '/posts/1/section',
              type: 'sections',
              id: nil
            },
            author: {
              self: '/posts/1/links/author',
              resource: '/posts/1/author',
              type: 'people',
              id: '1'
            },
            tags: {
              self: '/posts/1/links/tags',
              resource: '/posts/1/tags'
            },
            comments: {
              self: '/posts/1/links/comments',
              resource: '/posts/1/comments',
              type: 'comments',
              ids: ['1', '2']
            }
          }
        },
        linked: [
            {
              type: 'tags',
              id: '1',
              name: 'short',
              links: {
                self: '/tags/1',
                posts: {
                  self: '/tags/1/links/posts',
                  resource: '/tags/1/posts'
                }
              }
            },
            {
              type: 'tags',
              id: '2',
              name: 'whiny',
              links: {
                self: '/tags/2',
                posts: {
                  self: '/tags/2/links/posts',
                  resource: '/tags/2/posts'
                }
              }
            },
            {
              type: 'tags',
              id: '4',
              name: 'happy',
              links: {
                self: '/tags/4',
                posts: {
                  self: '/tags/4/links/posts',
                  resource: '/tags/4/posts',
                }
              }
            },
            {
              type: 'comments',
              id: '1',
              body: 'what a dumb post',
              links: {
                self: '/comments/1',
                author: {
                  self: '/comments/1/links/author',
                  resource: '/comments/1/author',
                  type: 'people',
                  id: '1'
                },
                post: {
                  self: '/comments/1/links/post',
                  resource: '/comments/1/post',
                  type: 'posts',
                  id: '1'
                },
                tags: {
                  self: '/comments/1/links/tags',
                  resource: '/comments/1/tags',
                  type: 'tags',
                  ids: ['1', '2']
                }
              }
            },
            {
              type: 'comments',
              id: '2',
              body: 'i liked it',
              links: {
                self: '/comments/2',
                author: {
                  self: '/comments/2/links/author',
                  resource: '/comments/2/author',
                  type: 'people',
                  id: '2'
                },
                post: {
                  self: '/comments/2/links/post',
                  resource: '/comments/2/post',
                  type: 'posts',
                  id: '1'
                },
                tags: {
                  self: '/comments/2/links/tags',
                  resource: '/comments/2/tags',
                  type: 'tags',
                  ids: ['4', '1']
                }
              }
            }
          ]
      },
      JSONAPI::ResourceSerializer.new(PostResource).serialize_to_hash(
        PostResource.new(@post), include: [:comments, 'comments.tags']))
  end

  def test_serializer_include_has_many_sub_objects_only

    assert_hash_equals(
      {
        data: {
          type: 'posts',
          id: '1',
          title: 'New post',
          body: 'A body!!!',
          subject: 'New post',
          links: {
            self: '/posts/1',
            section: {
              self: '/posts/1/links/section',
              resource: '/posts/1/section',
              type: 'sections',
              id: nil
            },
            author: {
              self: '/posts/1/links/author',
              resource: '/posts/1/author',
              type: 'people',
              id: '1'
            },
            tags: {
              self: '/posts/1/links/tags',
              resource: '/posts/1/tags'
            },
            comments: {
              self: '/posts/1/links/comments',
              resource: '/posts/1/comments'
            }
          }
        },
        linked: [
          {
            type: 'tags',
            id: '1',
            name: 'short',
            links: {
              self: '/tags/1',
              posts: {
                self: '/tags/1/links/posts',
                resource: '/tags/1/posts'
              }
            }
          },
          {
            type: 'tags',
            id: '2',
            name: 'whiny',
            links: {
              self: '/tags/2',
              posts: {
                self: '/tags/2/links/posts',
                resource: '/tags/2/posts'
              }
            }
          },
          {
            type: 'tags',
            id: '4',
            name: 'happy',
            links: {
              self: '/tags/4',
              posts: {
                self: '/tags/4/links/posts',
                resource: '/tags/4/posts',
              }
            }
          }
        ]
      },
      JSONAPI::ResourceSerializer.new(PostResource).serialize_to_hash(
        PostResource.new(@post), include: ['comments.tags']))
  end

  def test_serializer_include_has_one_sub_objects_only

    assert_hash_equals(
      {
        data: {
          type: 'posts',
          id: '1',
          title: 'New post',
          body: 'A body!!!',
          subject: 'New post',
          links: {
            self: '/posts/1',
            section: {
              self: '/posts/1/links/section',
              resource: '/posts/1/section',
              type: 'sections',
              id: nil
            },
            author: {
              self: '/posts/1/links/author',
              resource: '/posts/1/author',
              type: 'people',
              id: '1'
            },
            tags: {
              self: '/posts/1/links/tags',
              resource: '/posts/1/tags'
            },
            comments: {
              self: '/posts/1/links/comments',
              resource: '/posts/1/comments'
            }
          }
        },
        linked: [
          {
            type: 'comments',
            id: '1',
            body: 'what a dumb post',
            links: {
              self: '/comments/1',
              author: {
                self: '/comments/1/links/author',
                resource: '/comments/1/author',
                type: 'people',
                id: '1'
              },
              post: {
                self: '/comments/1/links/post',
                resource: '/comments/1/post',
                type: 'posts',
                id: '1'
              },
              tags: {
                self: '/comments/1/links/tags',
                resource: '/comments/1/tags'
              }
            }
          }
        ]
      },
      JSONAPI::ResourceSerializer.new(PostResource).serialize_to_hash(
        PostResource.new(@post), include: ['author.comments']))
  end

  def test_serializer_different_foreign_key

    assert_hash_equals(
      {
        data: {
          type: 'people',
          id: '2',
          name: 'Fred Reader',
          email: 'fred@xyz.fake',
          dateJoined: '2013-10-31 16:25:00 -0400',
          links: {
            self: '/people/2',
            posts: {
              self: '/people/2/links/posts',
              resource: '/people/2/posts'
            },
            comments: {
              self: '/people/2/links/comments',
              resource: '/people/2/comments',
              type: 'comments',
              ids: ['2', '3']
            }
          }
        },
        linked: [
          {
            type: 'comments',
            id: '2',
            body: 'i liked it',
            links: {
              self: '/comments/2',
              author: {
                self: '/comments/2/links/author',
                resource: '/comments/2/author',
                type: 'people',
                id: '2'
              },
              post: {
                self: '/comments/2/links/post',
                resource: '/comments/2/post',
                type: 'posts',
                id: '1'
              },
              tags: {
                self: '/comments/2/links/tags',
                resource: '/comments/2/tags'
              }
            }
          },
          {
            type: 'comments',
            id: '3',
            body: 'Thanks man. Great post. But what is JR?',
            links: {
              self: '/comments/3',
              author: {
                self: '/comments/3/links/author',
                resource: '/comments/3/author',
                type: 'people',
                id: '2'
              },
              post: {
                self: '/comments/3/links/post',
                resource: '/comments/3/post',
                type: 'posts',
                id: '2'
              },
              tags: {
                self: '/comments/3/links/tags',
                resource: '/comments/3/tags'
              }
            }
          }
        ]
      },
      JSONAPI::ResourceSerializer.new(PersonResource).serialize_to_hash(
        PersonResource.new(@fred), include: ['comments']))
  end

  def test_serializer_array_of_resources

    posts = []
    Post.find(1, 2).each do |post|
      posts.push PostResource.new(post)
    end

    assert_hash_equals(
      {
        data: [
          {
            type: 'posts',
            id: '1',
            title: 'New post',
            body: 'A body!!!',
            subject: 'New post',
            links: {
              self: '/posts/1',
              section: {
                self: '/posts/1/links/section',
                resource: '/posts/1/section',
                type: 'sections',
                id: nil
              },
              author: {
                self: '/posts/1/links/author',
                resource: '/posts/1/author',
                type: 'people',
                id: '1'
              },
              tags: {
                self: '/posts/1/links/tags',
                resource: '/posts/1/tags'
              },
              comments: {
                self: '/posts/1/links/comments',
                resource: '/posts/1/comments',
                type: 'comments',
                ids: ['1', '2']
              }
            }
          },
          {
            type: 'posts',
            id: '2',
            title: 'JR Solves your serialization woes!',
            body: 'Use JR',
            subject: 'JR Solves your serialization woes!',
            links: {
              self: '/posts/2',
              section: {
                self: '/posts/2/links/section',
                resource: '/posts/2/section',
                type: 'sections',
                id: '3'
              },
              author: {
                self: '/posts/2/links/author',
                resource: '/posts/2/author',
                type: 'people',
                id: '1'
              },
              tags: {
                self: '/posts/2/links/tags',
                resource: '/posts/2/tags'
              },
              comments: {
                self: '/posts/2/links/comments',
                resource: '/posts/2/comments',
                type: 'comments',
                ids: ['3']
              }
            }
          }
        ],
        linked: [
          {
            type: 'tags',
            id: '1',
            name: 'short',
            links: {
              self: '/tags/1',
              posts: {
                self: '/tags/1/links/posts',
                resource: '/tags/1/posts'
              }
            }
          },
          {
            type: 'tags',
            id: '2',
            name: 'whiny',
            links: {
              self: '/tags/2',
              posts: {
                self: '/tags/2/links/posts',
                resource: '/tags/2/posts'
              }
            }
          },
          {
            type: 'tags',
            id: '4',
            name: 'happy',
            links: {
              self: '/tags/4',
              posts: {
                self: '/tags/4/links/posts',
                resource: '/tags/4/posts',
              }
            }
          },
          {
            type: 'tags',
            id: '5',
            name: 'JR',
            links: {
              self: '/tags/5',
              posts: {
                self: '/tags/5/links/posts',
                resource: '/tags/5/posts',
              }
            }
          },
          {
            type: 'comments',
            id: '1',
            body: 'what a dumb post',
            links: {
              self: '/comments/1',
              author: {
                self: '/comments/1/links/author',
                resource: '/comments/1/author',
                type: 'people',
                id: '1'
              },
              post: {
                self: '/comments/1/links/post',
                resource: '/comments/1/post',
                type: 'posts',
                id: '1'
              },
              tags: {
                self: '/comments/1/links/tags',
                resource: '/comments/1/tags',
                type: 'tags',
                ids: ['1', '2']
              }
            }
          },
          {
            type: 'comments',
            id: '2',
            body: 'i liked it',
            links: {
              self: '/comments/2',
              author: {
                self: '/comments/2/links/author',
                resource: '/comments/2/author',
                type: 'people',
                id: '2'
              },
              post: {
                self: '/comments/2/links/post',
                resource: '/comments/2/post',
                type: 'posts',
                id: '1'
              },
              tags: {
                self: '/comments/2/links/tags',
                resource: '/comments/2/tags',
                type: 'tags',
                ids: ['4', '1']
              }
            }
          },
          {
            type: 'comments',
            id: '3',
            body: 'Thanks man. Great post. But what is JR?',
            links: {
              self: '/comments/3',
              author: {
                self: '/comments/3/links/author',
                resource: '/comments/3/author',
                type: 'people',
                id: '2'
              },
              post: {
                self: '/comments/3/links/post',
                resource: '/comments/3/post',
                type: 'posts',
                id: '2'
              },
              tags: {
                self: '/comments/3/links/tags',
                resource: '/comments/3/tags',
                type: 'tags',
                ids: ['5']
              }
            }
          }
        ]
      },
      JSONAPI::ResourceSerializer.new(PostResource).serialize_to_hash(
        posts, include: ['comments', 'comments.tags']))
  end

  def test_serializer_array_of_resources_limited_fields

    posts = []
    Post.find(1, 2).each do |post|
      posts.push PostResource.new(post)
    end

    assert_hash_equals(
      {
        data: [
          {
            type: 'posts',
            id: '1',
            title: 'New post',
            links: {
              self: '/posts/1',
              author: {
                self: '/posts/1/links/author',
                resource: '/posts/1/author',
                type: 'people',
                id: '1'
              }
            }
          },
          {
            type: 'posts',
            id: '2',
            title: 'JR Solves your serialization woes!',
            links: {
              self: '/posts/2',
              author: {
                self: '/posts/2/links/author',
                resource: '/posts/2/author',
                type: 'people',
                id: '1'
              }
            }
          }
        ],
        linked: [
          {
            type: 'posts',
            id: '11',
            title: 'JR How To',
            links: {
              self: '/posts/11',
              author: {
                self: '/posts/11/links/author',
                resource: '/posts/11/author',
                type: 'people',
                id: '1'
              }
            }
          },
          {
            type: 'people',
            id: '1',
            email: 'joe@xyz.fake',
            links: {
              self: '/people/1',
              comments: {
                self: '/people/1/links/comments',
                resource: '/people/1/comments'
              }
            }
          },
          {
            id: '1',
            type: 'tags',
            name: 'short',
            links: {
              self: '/tags/1'
            }
          },
          {
            id: '2',
            type: 'tags',
            name: 'whiny',
            links: {
              self: '/tags/2'
            }
          },
          {
            id: '4',
            type: 'tags',
            name: 'happy',
            links: {
              self: '/tags/4'
            }
          },
          {
            id: '5',
            type: 'tags',
            name: 'JR',
            links: {
              self: '/tags/5'
            }
          },
          {
            type: 'comments',
            id: '1',
            body: 'what a dumb post',
            links: {
              self: '/comments/1',
              post: {
                self: '/comments/1/links/post',
                resource: '/comments/1/post',
                type: 'posts',
                id: '1'
              }
            }
          },
          {
            type: 'comments',
            id: '2',
            body: 'i liked it',
            links: {
              self: '/comments/2',
              post: {
                self: '/comments/2/links/post',
                resource: '/comments/2/post',
                type: 'posts',
                id: '1'
              }
            }
          },
          {
            type: 'comments',
            id: '3',
            body: 'Thanks man. Great post. But what is JR?',
            links: {
              self: '/comments/3',
              post: {
                self: '/comments/3/links/post',
                resource: '/comments/3/post',
                type: 'posts',
                id: '2'
              }
            }
          }
        ]
      },
      JSONAPI::ResourceSerializer.new(PostResource).serialize_to_hash(
        posts,
        include: ['comments', 'author', 'comments.tags', 'author.posts'],
        fields: {
          people: [:id, :email, :comments],
          posts: [:id, :title, :author],
          tags: [:name],
          comments: [:id, :body, :post]
        }))
  end

  def test_serializer_camelized_with_value_formatters
    assert_hash_equals(
      {
        data: {
          type: 'expense_entries',
          id: '1',
          transactionDate: '04/15/2014',
          cost: 12.05,
          links: {
            self: '/expense_entries/1',
            isoCurrency: {
              self: '/expense_entries/1/links/iso_currency',
              resource: '/expense_entries/1/iso_currency',
              type: 'iso_currencies',
              id: 'USD'
            },
            employee: {
              self: '/expense_entries/1/links/employee',
              resource: '/expense_entries/1/employee',
              type: 'people',
              id: '3'
            }
          }
        },
        linked: [
          {
            type: 'iso_currencies',
            id: 'USD',
            countryName: 'United States',
            name: 'United States Dollar',
            minorUnit: 'cent',
            links: {
              self: '/iso_currencies/USD'
            }
          },
          {
            type: 'people',
            id: '3',
            email: 'lazy@xyz.fake',
            name: 'Lazy Author',
            dateJoined: '2013-10-31 17:25:00 -0400',
            links: {
              self: '/people/3',
            }
          }
        ]
      },
      JSONAPI::ResourceSerializer.new(ExpenseEntryResource).serialize_to_hash(
        ExpenseEntryResource.new(@expense_entry),
        include: ['iso_currency', 'employee'],
        fields: {people: [:id, :name, :email, :date_joined]}
      )
    )
  end

  def test_serializer_empty_links_null_and_array
    planet_hash = JSONAPI::ResourceSerializer.new(PlanetResource).serialize_to_hash(
      PlanetResource.new(Planet.find(8)))

    assert_hash_equals(
      {
        data: {
          type: 'planets',
          id: '8',
          name: 'Beta W',
          description: 'Newly discovered Planet W',
          links: {
            self: '/planets/8',
            planetType: {
              self: '/planets/8/links/planet_type',
              resource: '/planets/8/planet_type',
              type: 'planet_types',
              id: nil
            },
            tags: {
              self: '/planets/8/links/tags',
              resource: '/planets/8/tags'
            },
            moons: {
              self: '/planets/8/links/moons',
              resource: '/planets/8/moons'
            }
          }
        }
      }, planet_hash)
  end

  def test_serializer_include_with_empty_links_null_and_array
    planets = []
    Planet.find(7, 8).each do |planet|
      planets.push PlanetResource.new(planet)
    end

    planet_hash = JSONAPI::ResourceSerializer.new(PlanetResource).serialize_to_hash(
      planets,
      include: ['planet_type'],
      fields: { planet_types: [:id, :name] }
    )

    assert_hash_equals(
      {
        data: [{
          type: 'planets',
          id: '7',
          name: 'Beta X',
          description: 'Newly discovered Planet Z',
          links: {
            self: '/planets/7',
            planetType: {
              self: '/planets/7/links/planet_type',
              resource: '/planets/7/planet_type',
              type: 'planet_types',
              id: '5'
            },
            tags: {
              self: '/planets/7/links/tags',
              resource: '/planets/7/tags'
            },
            moons: {
              self: '/planets/7/links/moons',
              resource: '/planets/7/moons'
            }
          }
        },
        {
          type: 'planets',
          id: '8',
          name: 'Beta W',
          description: 'Newly discovered Planet W',
          links: {
            self: '/planets/8',
            planetType: {
              self: '/planets/8/links/planet_type',
              resource: '/planets/8/planet_type',
              type: 'planet_types',
              id: nil
            },
            tags: {
              self: '/planets/8/links/tags',
              resource: '/planets/8/tags'
            },
            moons: {
              self: '/planets/8/links/moons',
              resource: '/planets/8/moons'
            }
          }
        }
      ],
      linked: [
        {
          type: 'planet_types',
          id: '5',
          name: 'unknown',
          links: {
            self: '/planet_types/5'
          }
        }
      ]
    }, planet_hash)
  end

  def test_serializer_booleans
    JSONAPI.configuration.json_key_format = :underscored_key

    preferences = PreferencesResource.new(Preferences.find(1))

    assert_hash_equals(
      {
        data: {
          type: 'preferences',
          id: '1',
          advanced_mode: false,
          links: {
            self: '/preferences/1',
            author: {
              self: '/preferences/1/links/author',
              resource: '/preferences/1/author',
              type: 'authors',
              id: nil
            },
            friends: {
              self: '/preferences/1/links/friends',
              resource: '/preferences/1/friends'
            }
          }
        }
      },
      JSONAPI::ResourceSerializer.new(PreferencesResource).serialize_to_hash(preferences))
  end

  def test_serializer_data_types
    JSONAPI.configuration.json_key_format = :underscored_key

    facts = FactResource.new(Fact.find(1))

    assert_hash_equals(
      {
        data: {
          type: 'facts',
          id: '1',
          spouse_name: 'Jane Author',
          bio: 'First man to run across Antartica.',
          quality_rating: 23.89/45.6,
          salary: BigDecimal('47000.56', 30),
          date_time_joined: DateTime.parse('2013-08-07 20:25:00 UTC +00:00'),
          birthday: Date.parse('1965-06-30'),
          bedtime: Time.parse('2000-01-01 20:00:00 UTC +00:00'), #DB seems to set the date to 2001-01-01 for time types
          photo: "abc",
          cool: false,
          links: {
            self: '/facts/1'
          }
        }
      },
      JSONAPI::ResourceSerializer.new(FactResource).serialize_to_hash(facts))
  end
end
