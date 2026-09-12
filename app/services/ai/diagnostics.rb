module Ai
  class Diagnostics
    class << self
      def record(data)
        @latest = data.merge(recorded_at: Time.current).deep_stringify_keys
      end

      def latest
        @latest || {}
      end
    end
  end
end
