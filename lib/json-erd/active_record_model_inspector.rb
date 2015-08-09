class ActiveRecordModelInspector < ModelInspector
  def db
    "postgres" # technically we should detect postgres vs mysql
  end

  def table
    model.table_name
  end

  def fields
    @fields ||= model.attribute_names
  end

  def relations
    active_record_relations + active_mongoid_relations
  end

  def active_record_relations
    model.reflections.map do |key, desc|
      {
        type: "active_record",
        relationshipType: desc.macro.to_s,
        class: desc.class_name,
        accessor: key
      }
    end
  end
end
