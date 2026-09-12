module Ai
  class ProviderRegistry
    class UnknownProvider < StandardError; end

    PROVIDER_NAME = "mimo".freeze

    def self.fetch(name = PROVIDER_NAME)
      raise UnknownProvider, "Unknown AI provider" unless name.to_s == PROVIDER_NAME

      Ai::Providers::XiaomiMimo.new
    end

    def self.enabled = [ fetch ].select(&:enabled?)
    def self.default_name = PROVIDER_NAME
    def self.names = [ PROVIDER_NAME ]
  end
end
