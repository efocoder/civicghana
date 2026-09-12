require "net/http"

class SourceUrlHealthCheckJob < ApplicationJob
  queue_as :default

  def perform
    Source.where(active: true).find_each do |source|
      uri = URI.parse(source.url)
      next unless %w[http https].include?(uri.scheme)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
        http.head(uri.request_uri.presence || "/")
      end
      source.update_columns(last_checked_at: Time.current, active: response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection), updated_at: Time.current)
    rescue URI::InvalidURIError, SocketError, SystemCallError, Timeout::Error
      source.update_columns(last_checked_at: Time.current, updated_at: Time.current)
    end
  end
end
