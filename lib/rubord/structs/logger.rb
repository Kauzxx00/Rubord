module Rubord
  module Logger
    def self.success(message)
      puts "\e[32m✔ #{message}\e[0m"
    end

    def self.info(message)
      puts "\e[36mℹ #{message}\e[0m"
    end

    def self.warn(message)
      puts "\e[33m⚠ #{message}\e[0m"
    end

    def self.error(message)
      puts "\e[31m✖ #{message}\e[0m"
    end
  end
end