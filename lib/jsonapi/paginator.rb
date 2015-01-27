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
          paginator_class_name = "#{paginator.to_s.camelize}Paginator"
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
end

class OffsetPaginator < JSONAPI::Paginator
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

class PagedPaginator < JSONAPI::Paginator
  def initialize(params)
    parse_pagination_params(params)
  end

  def apply(relation)
    offset = (@number - 1) * @size
    relation.offset(offset).limit(@size)
  end

  private
  def parse_pagination_params(params)
    if params.nil?
      @number = 1
      @size = JSONAPI.configuration.default_page_size
    elsif params.is_a?(ActionController::Parameters)
      validparams = params.permit(:number, :size)

      @size = validparams[:size] ? validparams[:size].to_i : JSONAPI.configuration.default_page_size
      @number = validparams[:number] ? validparams[:number].to_i : 1

      if @size < 1
        raise JSONAPI::Exceptions::InvalidPageValue.new(:size, validparams[:size])
      elsif @size > JSONAPI.configuration.maximum_page_size
        raise JSONAPI::Exceptions::InvalidPageValue.new(:size, validparams[:size],
                                                        "size exceeds maximum page size of #{JSONAPI.configuration.maximum_page_size}.")
      end
    else
      @size = JSONAPI.configuration.default_page_size
      @number = params.to_i
    end
  rescue ActionController::UnpermittedParameters => e
    raise JSONAPI::Exceptions::PageParametersNotAllowed.new(e.params)
  end
end
