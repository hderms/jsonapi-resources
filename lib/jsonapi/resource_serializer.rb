module JSONAPI
  class ResourceSerializer

    def initialize(primary_resource_klass)
      @primary_resource_klass = primary_resource_klass
      @primary_class_name = @primary_resource_klass._type
    end

    # Converts a single resource, or an array of resources to a hash, conforming to the JSONAPI structure
    # include:
    #     Purpose: determines which objects will be side loaded with the source objects in a linked section
    #     Example: ['comments','author','comments.tags','author.posts']
    # fields:
    #     Purpose: determines which fields are serialized for a resource type. This encompasses both attributes and
    #              association ids in the links section for a resource. Fields are global for a resource type.
    #     Example: { people: [:id, :email, :comments], posts: [:id, :title, :author], comments: [:id, :body, :post]}
    def serialize_to_hash(source, options = {})
      is_resource_collection = source.respond_to?(:to_ary)

      @fields =  options.fetch(:fields, {})
      include = options.fetch(:include, [])

      @key_formatter = options.fetch(:key_formatter, JSONAPI.configuration.key_formatter)
      @base_url = options.fetch(:base_url, '')

      @linked_objects = {}

      requested_associations = parse_includes(include)

      process_primary(source, requested_associations)

      linked_objects = []
      primary_objects = []
      @linked_objects.each_value do |objects|
        objects.each_value do |object|
          if object[:primary]
            primary_objects.push(object[:object_hash])
          else
            linked_objects.push(object[:object_hash])
          end
        end
      end

      primary_hash = {data: is_resource_collection ? primary_objects : primary_objects[0]}

      if linked_objects.size > 0
        primary_hash[:linked] = linked_objects
      else
        primary_hash
      end
      primary_hash
    end

    private
    # Convert an array of associated objects to include along with the primary document in the form of
    # ['comments','author','comments.tags','author.posts'] into a structure that tells what we need to include
    # from each association.
    def parse_includes(includes)
      requested_associations = {}
      includes.each do |include|
        include = include.to_s.underscore

        pos = include.index('.')
        if pos
          association_name = include[0, pos].to_sym
          requested_associations[association_name] ||= {}
          requested_associations[association_name].store(:include_children, true)
          requested_associations[association_name].store(:include_related, parse_includes([include[pos+1, include.length]]))
        else
          association_name = include.to_sym
          requested_associations[association_name] ||= {}
          requested_associations[association_name].store(:include, true)
        end
      end if includes.is_a?(Array)
      return requested_associations
    end

    # Process the primary source object(s). This will then serialize associated object recursively based on the
    # requested includes. Fields are controlled fields option for each resource type, such
    # as fields: { people: [:id, :email, :comments], posts: [:id, :title, :author], comments: [:id, :body, :post]}
    # The fields options controls both fields and included links references.
    def process_primary(source, requested_associations)
      if source.respond_to?(:to_ary)
        source.each do |resource|
          id = resource.id
          if already_serialized?(@primary_class_name, id)
            set_primary(@primary_class_name, id)
          end

          add_linked_object(@primary_class_name, id, object_hash(resource,  requested_associations), true)
        end
      else
        resource = source
        id = resource.id
        # ToDo: See if this is actually needed
        # if already_serialized?(@primary_class_name, id)
        #   set_primary(@primary_class_name, id)
        # end

        add_linked_object(@primary_class_name, id, object_hash(source,  requested_associations), true)
      end
    end

    # Returns a serialized hash for the source model, with
    def object_hash(source, requested_associations)
      obj_hash = attribute_hash(source)
      links = links_hash(source, requested_associations)

      # ToDo: Do we format these required keys
      obj_hash[format_key('type')] = format_value(source.class._type.to_s, :default, source)
      obj_hash[format_key('id')] ||= format_value(source.id, :id, source)
      obj_hash.merge!({links: links}) unless links.empty?
      return obj_hash
    end

    def requested_fields(model)
      @fields[model] if @fields
    end

    def attribute_hash(source)
      requested = requested_fields(source.class._type)
      fields = source.fetchable_fields & source.class._attributes.keys.to_a
      unless requested.nil?
        fields = requested & fields
      end

      fields.each_with_object({}) do |name, hash|
        format = source.class._attribute_options(name)[:format]
        if format == :default && name == :id
          format = 'id'
        end
        hash[format_key(name)] = format_value(
          source.send(name),
          format,
          source
        )
      end
    end

    # Returns a hash of links for the requested associations for a resource, filtered by the resource
    # class's fetchable method
    def links_hash(source, requested_associations)
      associations = source.class._associations
      requested = requested_fields(source.class._type)
      fields = associations.keys
      unless requested.nil?
        fields = requested & fields
      end

      field_set = Set.new(fields)

      included_associations = source.fetchable_fields & associations.keys

      links = {}
      links[:self] = source.self_href(@base_url)

      associations.each_with_object(links) do |(name, association), hash|
        if included_associations.include? name
          ia = requested_associations.is_a?(Hash) ? requested_associations[name] : nil

          include_linked_object = ia && ia[:include]
          include_linked_children = ia && ia[:include_children]

          if field_set.include?(name)
            hash[format_key(name)] = link_object(source, association, include_linked_object)
          end

          type = association.type

          # If the object has been serialized once it will be in the related objects list,
          # but it's possible all children won't have been captured. So we must still go
          # through the associations.
          if include_linked_object || include_linked_children
            if association.is_a?(JSONAPI::Association::HasOne)
              resource = source.send(name)
              if resource
                id = resource.id
                associations_only = already_serialized?(type, id)
                if include_linked_object && !associations_only
                  add_linked_object(type, id, object_hash(resource, ia[:include_related]))
                elsif include_linked_children || associations_only
                  links_hash(resource, ia[:include_related])
                end
              end
            elsif association.is_a?(JSONAPI::Association::HasMany)
              resources = source.send(name)
              resources.each do |resource|
                id = resource.id
                associations_only = already_serialized?(type, id)
                if include_linked_object && !associations_only
                  add_linked_object(type, id, object_hash(resource, ia[:include_related]))
                elsif include_linked_children || associations_only
                  links_hash(resource, ia[:include_related])
                end
              end
            end
          end
        end
      end
    end

    def already_serialized?(type, id)
      type = format_key(type)
      return @linked_objects.key?(type) && @linked_objects[type].key?(id)
    end

    def format_route(route)
      JSONAPI.configuration.route_formatter.format(route.to_s)
    end

    def link_object_has_one(source, association)
      route = association.name

      link_object_hash = {}
      link_object_hash[:self] = "#{source.self_href(@base_url)}/links/#{format_route(route)}"
      link_object_hash[:resource] = "#{source.self_href(@base_url)}/#{format_route(route)}"
      # ToDo: Get correct formatting figured out
      link_object_hash[:type] = format_route(association.type)
      link_object_hash[:id] = foreign_key_value(source, association)
      link_object_hash
    end

    def link_object_has_many(source, association, include_linked_object)
      route = association.name

      link_object_hash = {}
      link_object_hash[:self] = "#{source.self_href(@base_url)}/links/#{format_route(route)}"
      link_object_hash[:resource] = "#{source.self_href(@base_url)}/#{format_route(route)}"
      if include_linked_object
        # ToDo: Get correct formatting figured out
        link_object_hash[:type] = format_route(association.type)
        link_object_hash[:ids] = foreign_key_value(source, association)
      end
      link_object_hash
    end

    def link_object(source, association, include_linked_object = false)
      if association.is_a?(JSONAPI::Association::HasOne)
        link_object_has_one(source, association)
      elsif association.is_a?(JSONAPI::Association::HasMany)
        link_object_has_many(source, association, include_linked_object)
      end
    end

    # Extracts the foreign key value for an association.
    def foreign_key_value(source, association)
      foreign_key = association.foreign_key
      value = source.send(foreign_key)

      if association.is_a?(JSONAPI::Association::HasMany)
        value.map { |value| IdValueFormatter.format(value, {}) }
      elsif association.is_a?(JSONAPI::Association::HasOne)
        IdValueFormatter.format(value, {})
      end
    end

    # Sets that an object should be included in the primary document of the response.
    def set_primary(type, id)
      type = format_key(type)
      @linked_objects[type][id][:primary] = true
    end

    # Collects the hashes for all objects processed by the serializer
    def add_linked_object(type, id, object_hash, primary = false)
      type = format_key(type)

      unless @linked_objects.key?(type)
        @linked_objects[type] = {}
      end

      if already_serialized?(type, id)
        if primary
          set_primary(type, id)
        end
      else
        @linked_objects[type].store(id, {primary: primary, object_hash: object_hash})
      end
    end

    def format_key(key)
      @key_formatter.format(key)
    end

    def format_value(value, format, source)
      value_formatter = JSONAPI::ValueFormatter.value_formatter_for(format)
      value_formatter.format(value, source)
    end
  end
end
