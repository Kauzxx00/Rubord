# loader.rb
module Rubord
  class CommandLoader
    def self.load(path, client, registry)
      full_path = File.expand_path(path)
      files = Dir["#{full_path}/**/*.rb"]

      files.each do |file|
        begin
          Kernel.load(file)
        rescue => e
          puts "[Rubord:Commands] ERRO ao carregar #{file}:"
          puts "  #{e.class}: #{e.message}"
        end
      end

      found_classes = []
      ObjectSpace.each_object(Class) do |klass|
        next if klass == Rubord::CommandBase

        if klass.ancestors.include?(Rubord::CommandBase)
          found_classes << klass
        end
      end

      found_classes.each do |klass|
        begin
          registry.register(klass, client)
        rescue => e
          puts "[Rubord:Commands] ERRO ao registrar #{klass}:"
          puts "  #{e.class}: #{e.message}"
        end
      end
    end
  end
end