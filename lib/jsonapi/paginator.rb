module JSONAPI
  class Paginator
    def initialize(params)
    end

    def apply(relation)
      # :nocov:
      relation
      # :nocov:
    end

    class << self
      # :nocov:
      if RUBY_VERSION >= '2.0'
        def paginator_for(paginator)
          # ToDo: Figure out why we need the module here
          paginator_class_name = "JSONAPI::#{paginator.to_s.camelize}Paginator"
          Object.const_get(paginator_class_name) if paginator_class_name
        end
      else
        def paginator_for(paginator)
          paginator_class_name = "#{paginator.to_s.camelize}Paginator"
          paginator_class_name.safe_constantize if paginator_class_name
        end
      end
      # :nocov:
    end
  end

  class OffsetPaginator < Paginator
    def initialize(params)
      parse_pagination_params(params)
    end

    def apply(relation)
      relation.offset(@offset).limit(@limit)
    end

    private
    def parse_pagination_params(params)
      if params.nil?
        @offset = 0
        @limit = JSONAPI.configuration.default_page_size
      elsif params.is_a?(ActionController::Parameters)
        validparams = params.permit(:offset, :limit)

        @offset = validparams[:offset] ? validparams[:offset].to_i : 0
        @limit = validparams[:limit] ? validparams[:limit].to_i : JSONAPI.configuration.default_page_size

        if @limit < 1
          raise JSONAPI::Exceptions::InvalidPageValue.new(:limit, validparams[:limit])
        elsif @limit > JSONAPI.configuration.maximum_page_size
          raise JSONAPI::Exceptions::InvalidPageValue.new(:limit, validparams[:limit],
                                                          "Limit exceeds maximum page size of #{JSONAPI.configuration.maximum_page_size}.")
        end
      else
        raise JSONAPI::Exceptions::InvalidPageObject.new
      end
    rescue ActionController::UnpermittedParameters => e
      raise JSONAPI::Exceptions::PageParametersNotAllowed.new(e.params)
    end
  end

  class PagedPaginator < Paginator
    def initialize(params)
      parse_pagination_params(params)
    end

    def apply(relation)
      relation.offset(@offset).limit(@limit)
    end

    private
    def parse_pagination_params(params)
      if params.nil?
        @offset = 0
        @limit = JSONAPI.configuration.default_page_size
      elsif params.is_a?(ActionController::Parameters)
        validparams = params.permit(:page, :limit)

        @limit = validparams[:limit] ? validparams[:limit].to_i : JSONAPI.configuration.default_page_size
        @offset = (validparams[:page] ? validparams[:page].to_i : 0) * @limit

        if @limit < 1
          raise JSONAPI::Exceptions::InvalidPageValue.new(:limit, validparams[:limit])
        elsif @limit > JSONAPI.configuration.maximum_page_size
          raise JSONAPI::Exceptions::InvalidPageValue.new(:limit, validparams[:limit],
                                                          "Limit exceeds maximum page size of #{JSONAPI.configuration.maximum_page_size}.")
        end
      else
        @limit = JSONAPI.configuration.default_page_size
        @offset = params.to_i * @limit
      end
    rescue ActionController::UnpermittedParameters => e
      raise JSONAPI::Exceptions::PageParametersNotAllowed.new(e.params)
    end
  end
end
