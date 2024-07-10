require "net/http"
require "json"

class AnalyticsImportService
  API_ENDPOINT = "https://api.heyering.com/analytics".freeze
  API_KEY = "api-key-here"
  BATCH_SIZE = 20.freeze
  REQUEST_DELAY = 10.freeze # one request per 10 seconds

  def send_records(enriched_logs)
    total_imported = 0
    enriched_logs.each_slice(BATCH_SIZE) do |logs_chunk|
      response = send_chunk(logs_chunk)
      handle_response(response, total_imported)
      sleep REQUEST_DELAY
    end
    total_imported
  end

  private

  def send_chunk(record_chunk)
    uri = URI(API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
    request.body = record_chunk.to_json
    request["Authorization"] = API_KEY

    http.request(request)
  end

  def handle_response(response, total_imported)
    case response
    when Net::HTTPSuccess
      body = JSON.parse(response.body)
      imported_count = body["itemsIngested"]
      total_imported += imported_count
    when Net::HTTPTooManyRequests
      # add some logging here
      sleep REQUEST_DELAY
    else
      # log: "Error sending records: #{response.code} - #{response.message}"
    end
  end
end