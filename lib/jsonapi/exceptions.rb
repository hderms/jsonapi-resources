module JSONAPI
  module Exceptions
    class Error < RuntimeError; end

    class InvalidResource < Error
      attr_accessor :resource
      def initialize(resource)
        @resource = resource
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::INVALID_RESOURCE,
                             status: :bad_request,
                             title: 'Invalid resource',
                             detail: "#{resource} is not a valid resource.")]
      end
    end

    class RecordNotFound < Error
      attr_accessor :id
      def initialize(id)
        @id = id
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::RECORD_NOT_FOUND,
                             status: :not_found,
                             title: 'Record not found',
                             detail: "The record identified by #{id} could not be found.")]
      end
    end

    class HasManyRelationExists < Error
      attr_accessor :id
      def initialize(id)
        @id = id
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::RELATION_EXISTS,
                            status: :bad_request,
                            title: 'Relation exists',
                            detail: "The relation to #{id} already exists.")]
      end
    end

    class HasOneRelationExists < Error
      def initialize
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::RELATION_EXISTS,
                            status: :bad_request,
                            title: 'Relation exists',
                            detail: 'The relation already exists.')]
      end
    end

    class FilterNotAllowed < Error
      attr_accessor :filter
      def initialize(filter)
        @filter = filter
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::FILTER_NOT_ALLOWED,
                             status: :bad_request,
                             title: 'Filter not allowed',
                             detail: "#{filter} is not allowed.")]
      end
    end

    class InvalidFilterValue < Error
      attr_accessor :filter, :value
      def initialize(filter, value)
        @filter = filter
        @value = value
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::INVALID_FILTER_VALUE,
                             status: :bad_request,
                             title: 'Invalid filter value',
                             detail: "#{value} is not a valid value for #{filter}.")]
      end
    end

    class InvalidFieldValue < Error
      attr_accessor :field, :value
      def initialize(field, value)
        @field = field
        @value = value
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::INVALID_FIELD_VALUE,
                             status: :bad_request,
                             title: 'Invalid field value',
                             detail: "#{value} is not a valid value for #{field}.")]
      end
    end

    class InvalidLinksObject < Error
      attr_accessor :value
      def initialize(value)
        @value = value
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::INVALID_LINKS_OBJECT,
                            status: :bad_request,
                            title: 'Invalid Links Object',
                            detail: "#{value} is not a valid Links Object.")]
      end
    end

    class TypeMismatch < Error
      attr_accessor :type
      def initialize(type)
        @type = type
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::TYPE_MISMATCH,
                            status: :bad_request,
                            title: 'Type Mismatch',
                            detail: "#{type} is not a valid type for this operation.")]
      end
    end

    class InvalidField < Error
      attr_accessor :field, :type
      def initialize(type, field)
        @field = field
        @type = type
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::INVALID_FIELD,
                             status: :bad_request,
                             title: 'Invalid field',
                             detail: "#{field} is not a valid field for #{type}.")]
      end
    end

    class InvalidInclude < Error
      attr_accessor :association, :resource
      def initialize(resource, association)
        @resource = resource
        @association = association
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::INVALID_INCLUDE,
                            status: :bad_request,
                            title: 'Invalid field',
                            detail: "#{association} is not a valid association of #{resource}")]
      end
    end

    class InvalidSortParam < Error
      attr_accessor :sort_param, :resource
      def initialize(resource, sort_param)
        @resource = resource
        @sort_param = sort_param
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::INVALID_SORT_PARAM,
                            status: :bad_request,
                            title: 'Invalid sort param',
                            detail: "#{sort_param} is not a valid sort param for #{resource}")]
      end
    end

    class ParametersNotAllowed < Error
      attr_accessor :params
      def initialize(params)
        @params = params
      end

      def errors
            params.collect { |param|
              JSONAPI::Error.new(code: JSONAPI::PARAM_NOT_ALLOWED,
                             status: :bad_request,
                             title: 'Param not allowed',
                             detail: "#{param} is not allowed.")
            }

      end
    end

    class ParameterMissing < Error
      attr_accessor :param
      def initialize(param)
        @param = param
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::PARAM_MISSING,
                             status: :bad_request,
                             title: 'Missing Parameter',
                             detail: "The required parameter, #{param}, is missing.")]
      end
    end

    class CountMismatch < Error
      def errors
        [JSONAPI::Error.new(code: JSONAPI::COUNT_MISMATCH,
                              status: :bad_request,
                              title: 'Count to key mismatch',
                              detail: 'The resource collection does not contain the same number of objects as the number of keys.')]
      end
    end

    class KeyNotIncludedInURL < Error
      attr_accessor :key
      def initialize(key)
        @key = key
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::KEY_NOT_INCLUDED_IN_URL,
                              status: :bad_request,
                              title: 'Key is not included in URL',
                              detail: "The URL does not support the key #{key}")]
      end
    end

    class MissingKey < Error
      def errors
        [JSONAPI::Error.new(code: JSONAPI::KEY_ORDER_MISMATCH,
                              status: :bad_request,
                              title: 'A key is required',
                              detail: 'The resource object does not contain a key.')]
      end
    end

    class RecordLocked < Error
      attr_accessor :message
      def initialize(message)
        @message = message
      end

      def errors
        [JSONAPI::Error.new(code: JSONAPI::LOCKED,
                             status: :locked,
                             title: 'Locked resource',
                             detail: "#{message}")]
      end
    end

    class ValidationErrors < Error
      attr_accessor :messages
      def initialize(messages)
        @messages = messages
      end

      def errors
        messages.inject([]) do |arr, element|
          arr.concat(
            element[1].map do |message|
              JSONAPI::Error.new(code: JSONAPI::VALIDATION_ERROR,
                                 status: :unprocessable_entity,
                                 title: "#{element[0]} - #{message}",
                                 detail: message,
                                 path: "/#{element[0]}")
            end
          )
        end
      end
    end

  end
end
