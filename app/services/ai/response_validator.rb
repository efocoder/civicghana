module Ai
  class ResponseValidator
    FORBIDDEN_PATTERNS = [
      /\b\d{1,2}\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4}\b/i,
      /https?:\/\/[^\s]+/,
      /\b[\w.]+@[\w.]+\.[\w.]+\b/,
      /\b\d{10,}\b/
    ].freeze

    def self.call(...) = new(...).call

    def initialize(response:, known_dates: [], known_source_ids: [], known_urls: [])
      @response = response.to_s
      @known_dates = known_dates.map(&:to_s)
      @known_source_ids = known_source_ids.map(&:to_s)
      @known_urls = known_urls.map(&:to_s)
    end

    def call
      errors = []

      errors.concat(check_invented_dates)
      errors.concat(check_invented_urls)
      errors.concat(check_invented_contact_info)

      Result.new(valid: errors.empty?, errors: errors)
    end

    Result = Data.define(:valid, :errors)

    private

    attr_reader :response, :known_dates, :known_source_ids, :known_urls

    def check_invented_dates
      date_pattern = /\b(\d{1,2}\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4})\b/i
      found_dates = response.scan(date_pattern).flatten.map(&:strip)

      invented = found_dates.reject do |date|
        known_dates.any? { |kd| kd.include?(date) || date.include?(kd) }
      end

      invented.map { |d| "Invented date detected: #{d}" }
    end

    def check_invented_urls
      url_pattern = %r{https?://[^\s"')]+}
      found_urls = response.scan(url_pattern).flatten

      invented = found_urls.reject do |url|
        known_urls.any? { |ku| url.start_with?(ku) || ku.start_with?(url) }
      end

      invented.map { |u| "Invented URL detected: #{u}" }
    end

    def check_invented_contact_info
      errors = []

      if response.match?(/\b[\w.]+@[\w.]+\.[\w.]+\b/) && !known_urls.any? { |u| u.include?("@") }
        errors << "Possible invented email address detected"
      end

      errors
    end
  end
end
