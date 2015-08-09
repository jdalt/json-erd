require 'json-erd/model_inspector'
require 'json-erd/mongoid_model_inspector'
require 'json-erd/active_record_model_inspector'

module JsonErd
  require 'json-erd/railtie' if defined?(Rails)
end
