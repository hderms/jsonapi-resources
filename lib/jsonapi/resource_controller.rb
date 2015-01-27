require 'jsonapi/resource_for'
require 'jsonapi/resource_serializer'
require 'action_controller'
require 'jsonapi/exceptions'
require 'jsonapi/error'
require 'jsonapi/error_codes'
require 'jsonapi/request'
require 'jsonapi/operations_processor'
require 'jsonapi/active_record_operations_processor'
require 'csv'

module JSONAPI
  class ResourceController < ActionController::Base
    include ResourceFor

    before_filter :setup_request

    def index
      render json: JSONAPI::ResourceSerializer.new(resource_klass).serialize_to_hash(
          resource_klass.find(resource_klass.verify_filters(@request.filters, context),
            context: context, sort_params: @request.sort_params, paginator: @request.paginator),
          include: @request.include,
          fields: @request.fields,
          attribute_formatters: attribute_formatters,
          base_url: base_url,
          key_formatter: key_formatter)
    rescue => e
      handle_exceptions(e)
    end

    def show
      keys = parse_key_array(params[resource_klass._primary_key])

      resources = if keys.length > 1
                    resource_klass.find_by_keys(keys, context: context)
                  else
                    resource_klass.find_by_key(keys[0], context: context)
                  end

      render json: JSONAPI::ResourceSerializer.new(resource_klass).serialize_to_hash(
          resources,
          include: @request.include,
          fields: @request.fields,
          base_url: base_url,
          attribute_formatters: attribute_formatters,
          key_formatter: key_formatter)
    rescue => e
      handle_exceptions(e)
    end

    def show_association
      association_type = params[:association]

      parent_key = params[resource_klass._as_parent_key]

      parent_resource = resource_klass.find_by_key(parent_key, context: context)

      association = resource_klass._association(association_type)
      render json: { key_formatter.format(association_type) => parent_resource.send(association.foreign_key)}
    rescue => e
      # :nocov:
      handle_exceptions(e)
      # :nocov:
    end

    def create
      process_request_operations
    end

    def create_association
      process_request_operations
    end

    def update_association
      process_request_operations
    end

    def update
      process_request_operations
    end

    def destroy
      process_request_operations
    end

    def destroy_association
      process_request_operations
    end

    # Override this to use another operations processor
    def create_operations_processor
      JSONAPI::ActiveRecordOperationsProcessor.new
    end

    private
    # :nocov:
    if RUBY_VERSION >= '2.0'
      def resource_klass
        @resource_klass ||= Object.const_get resource_klass_name
      end
    else
      def resource_klass
        @resource_klass ||= resource_klass_name.safe_constantize
      end
    end
    # :nocov:

    def base_url
      @base_url ||= request.protocol + request.host_with_port
    end

    def resource_klass_name
      @resource_klass_name ||= "#{self.class.name.sub(/Controller$/, '').singularize}Resource"
    end

    def setup_request
      @request = JSONAPI::Request.new(params, {
        context: context,
        key_formatter: key_formatter
      })
      render_errors(@request.errors) unless @request.errors.empty?
    rescue => e
      # :nocov:
      handle_exceptions(e)
      # :nocov:
    end

    def parse_key_array(raw)
      keys = raw.nil? || raw.empty? ? [] : raw.split(',')
      resource_klass.verify_keys(keys, context)
    end

    # override to set context
    def context
      {}
    end

    # Control by setting in an initializer:
    #     JSONAPI.configuration.json_key_format = :camelized_key
    #
    # Override if you want to set a per controller key format.
    # Must return a class derived from KeyFormatter.
    def key_formatter
      JSONAPI.configuration.key_formatter
    end

    # override to setup custom attribute_formatters
    def attribute_formatters
      {}
    end

    def render_errors(errors)
      render(json: {errors: errors}, status: errors[0].status)
    end

    def process_request_operations
      op = create_operations_processor

      results = op.process(@request)

      errors = []
      resources = []

      results.each do |result|
        if result.has_errors?
          errors.concat(result.errors)
        else
          resources.push(result.resource) unless result.resource.nil?
        end
      end

      if errors.count > 0
        render status: errors[0].status, json: {errors: errors}
      else
        if results.length > 0 && resources.length > 0
          render status: results[0].code,
                 json: JSONAPI::ResourceSerializer.new(resource_klass).serialize_to_hash(
                   resources.length > 1 ? resources : resources[0],
                   include: @request.include,
                   fields: @request.fields,
                   base_url: base_url,
                   attribute_formatters: attribute_formatters,
                   key_formatter: key_formatter)
        else
          render status: results[0].code, json: nil
        end
      end
    rescue => e
      handle_exceptions(e)
    end

    # override this to process other exceptions
    # Note: Be sure to either call super(e) or handle JSONAPI::Exceptions::Error and raise unhandled exceptions
    def handle_exceptions(e)
      case e
        when JSONAPI::Exceptions::Error
          render_errors(e.errors)
        else # raise all other exceptions
          # :nocov:
          raise e
          # :nocov:
      end
    end
  end
end
