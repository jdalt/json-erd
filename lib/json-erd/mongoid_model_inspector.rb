class MongoidModelInspector < ModelInspector
  def db
    "mongo"
  end

  def collection
    model.collection_name
  end

  def fields
    @fields ||= begin
      model.fields.map do |key, desc|
        type = "[#{desc.options[:type]}]" if desc.options[:type]
        alias_name = "(#{desc.options[:as]})" if desc.options[:as]
        [key, alias_name, type].compact.join(" ")
      end
    end
  end

  def relations
    mongoid_relations + active_mongoid_relations
  end

  def mongoid_relations
    model.associations.map do |key, desc|
      {
        type: "mongoid",
        relationshipType: desc.macro.to_s,
        class: desc.class_name,
        accessor: key
      }
    end
  end
end
