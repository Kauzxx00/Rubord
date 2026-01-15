module Rubord
  class CommandLoader
    def self.load(path, client, registry)
      Dir["#{path}/**/*.rb"].each do |file|
        require file
      end

      ObjectSpace.each_object(Class) do |klass|
        next unless klass < Rubord::CommandBase
        registry.register(klass, client)
      end
    end
  end
end