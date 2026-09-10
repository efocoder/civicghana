module ServiceRules
  class Resolver
    class NotFound < StandardError; end
    class Ambiguous < StandardError; end

    def self.call(...) = new(...).call

    def initialize(public_service:, rule_type:, on: Date.current)
      @public_service = public_service
      @rule_type = rule_type
      @on = on
    end

    def call
      matches = public_service.service_rules
        .joins(:source)
        .merge(Source.verified)
        .verified
        .effective_on(on)
        .where(rule_type: rule_type)
        .includes(:source)
        .limit(2)
        .to_a

      raise NotFound, "No verified #{rule_type} rule applies on #{on}" if matches.empty?
      raise Ambiguous, "Multiple verified #{rule_type} rules apply on #{on}" if matches.many?

      matches.first
    end

    private

    attr_reader :public_service, :rule_type, :on
  end
end
