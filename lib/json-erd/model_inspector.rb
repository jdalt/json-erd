class ModelInspector
  attr_reader :model, :children

  def self.detect_and_build(model)
    if model.include?(Mongoid::Document)
      MongoidModelInspector.new(model)
    elsif model.ancestors.include?(ActiveRecord::Base)
      ActiveRecordModelInspector.new(model)
    end
  end

  def initialize(model)
    @model = model
    @children = []
  end

  def add_child(model_str)
    @children << model_str unless @children.include?(model_str)
  end

  def db
    nil
  end

  def name
    model.to_s
  end

  def collection
    nil
  end

  def table
    nil
  end

  def superClasess
    nil
  end

  def relations
    nil
  end

  def parents
    @parents ||= begin
      model.ancestors.select do |ancestor|
        valid_models.include?(ancestor) && !(ancestor == model)
      end.map(&:to_s)
    end
  end

  def active_mongoid_relations
    return [] unless model.respond_to?(:am_relations)
    model.am_relations.map do |key, desc|
      {
        type: "active_mongoid",
        relationshipType: desc.macro.to_s,
        class: desc.class_name,
        accessor: key
      }
    end
  end
end
