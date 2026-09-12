class BusinessDayCalculator
  def self.advance(date, working_days)
    current = date
    remaining = working_days.to_i
    while remaining.positive?
      current += 1.day
      remaining -= 1 unless current.saturday? || current.sunday?
    end
    current
  end
end
