module DSpace
  module CLI
    module OpenAccessRepository
      class Collection < CLI::Collection
        def self.find_by_department(department)
          return unless department_to_collection_map.key?(department)

          handle = department_to_collection_map[department]
          obj = handle_manager.resolveToObject(kernel.context, handle)
          return if obj.nil?

          new(obj)
        end
      end
    end
  end
end
