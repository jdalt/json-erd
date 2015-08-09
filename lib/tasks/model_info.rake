require 'optparse'

namespace :erd do |args|
  desc "Lists info for all the models"
  task :json => :environment do

    options = {}
    OptionParser.new(args) do |opts|
      opts.banner = "Usage: rake model_info:mongoid [options]"
      opts.on("-o", "--only {Models}","Exclusive models to check.", String) do |only|
        options[:only] = only
      end
      opts.on("-e", "--exclude {Models}","Exclude models in check.", String) do |exclude|
        options[:exclude] = exclude
      end
      opts.on("-p", "--print","Pretty print rather than json") do
        options[:pretty_print] = true
      end
      opts.on("-s", "--services","Include services and used in data") do
        options[:services] = true
      end
    end.parse!

    inspected_models = {}
    filtered_models(options).each do |model|
      inspected_models[model.to_s] = ModelInspector.detect_and_build(model)
    end

    inspected_models.each do |model_str, desc|
      desc.parents.each do |parent_str|
        parent = inspected_models[parent_str]
        parent.add_child(model_str) if parent # we might not have inspected the parent
      end
    end

    parent_models = inspected_models.values.select { |desc| desc.parents.all? { |p| inspected_models[p].nil? } }

    erd_json = parent_models.map do |m|
      {
        name: m.name,
        db: m.db,
        collection: m.collection,
        table: m.table,
        fields: m.fields,
        relations: m.relations,
        parents: m.parents,
        children: m.children
      }
    end.to_json

    # write_file = File.join(Rails.root,'tmp', 'erd.json')
    write_file = "#{Dir.home}/hackathon/shanty_board/public/export_models.json"
    File.open(write_file, 'w') { |file| file.write(erd_json) }

    puts ""
    puts "Results written to #{write_file}"

    exit
  end
end

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

def constantize_models_str(models_str)
  models_str.split(' ').map {|model_str| model_str.constantize }
end

def filtered_models(options)
  if options[:only]
    exclusive_models = constantize_models_str(options[:only])
    valid_models.select {|model| exclusive_models.include?(model) }
  elsif options[:exclude]
    bad_model_mines = options[:exclude].split(' ')
    valid_models.select do |model|
      bad_model_mines.none? do |word_mine|
        model.to_s.include?(word_mine)
      end
    end
  else
    valid_models
  end
end

def valid_models
  @valid_models ||= begin
    model_constants.select { |constant| constant.include?(Mongoid::Document) || constant.ancestors.include?(ActiveRecord::Base) }
  end
end

def model_constants
  @model_constants ||= begin
    model_paths = Dir["#{Rails.root}/app/models/**/*.rb"]
    sanitized_model_paths = model_paths.map { |path| path.gsub(/.*\/app\/models\//, '').gsub('.rb', '') }
    sanitized_model_paths.map do |path|
      begin
        path.camelize.constantize
      rescue NameError => e
        # need to log to stderrr:  "!! Unable to constantize model: #{e}"
      end
    end.compact
  end
end

# Useful to use when hitting a break point
# TODO: more complete compare - using merged keys
def compare_fields(m1, m2)
  m1.send(:aliased_fields).keys - m2.send(:aliased_fields).keys
end

def compare_methods(m1, m2)
  all_meth = m1.send(:instance_methods, false) - m2.send(:instance_methods, false)
  all_meth.reject { |meth| !meth.to_s[/^_/].nil? }
end
