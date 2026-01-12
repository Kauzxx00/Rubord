module Rubord
  module Components
    class BaseComponent
      attr_reader :type

      def initialize(type)
        @type = type
      end

      def to_h
        raise NotImplementedError, "Implement to_h in subclass"
      end
    end
  end
end