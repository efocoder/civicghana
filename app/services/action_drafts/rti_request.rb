module ActionDrafts
  class RtiRequest
    def self.call(...) = new(...).call

    def initialize(case_record:, information_requested:)
      @case_record = case_record
      @information_requested = information_requested
    end

    def call
      {
        subject: "Right to Information request — #{case_record.public_service.name}",
        body: build_body
      }
    end

    private

    attr_reader :case_record, :information_requested

    def build_body
      lines = []
      lines << "I am writing to request access to information under the Right to Information Act."
      lines << ""
      lines << "Information requested:"
      lines << (information_requested.present? ? information_requested : "[Describe the specific information you are seeking]")
      lines << ""
      lines << "Institution:"
      lines << case_record.public_service.institution.name
      lines << ""
      lines << "Relevant application/service:"
      lines << case_record.public_service.name
      lines << ""
      lines << "Application completed:"
      lines << format_date(case_record.application_completed_on)
      lines << ""
      lines << "I would appreciate a response within the statutory timeframe."
      lines << ""
      lines << "Thank you."

      lines.join("\n")
    end

    def format_date(date)
      date.strftime("%-d %B %Y")
    end
  end
end
