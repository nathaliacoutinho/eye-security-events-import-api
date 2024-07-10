class AnalyticsLogsEnrichmentService
  API_ENDPOINT = "https://api.heyering.com/enrichment".freeze
  API_KEY = "api-key-here"

  def enrich_record(log)
    sanitized_log = sanitize_category(log.transform_keys(&:to_sym))

    return unless sanitized_log.present? && valid_log?(sanitized_log)

    response = send_request(sanitized_log)

    if response.is_a?(Net::HTTPSuccess)
      enrichment_data = JSON.parse(response.body)
      # this is not ideal, at this point we are basically just appending whatever fields come back from the enrichment API
      # ideally we want to validate the fields before merging them to our log record, but lets keep it simple now
      sanitized_log.merge(enrichment_data).transform_keys(&:to_sym)
    else
      nil
      # add rails logging here
      # would be nice to save the records that failed to be enriched with their error message so the user could see why
    end
  end

  private

  def valid_log?(sanitized_log)
    sanitized_log[:id].present? && sanitized_log[:asset_name].present? && sanitized_log[:ip].present? && sanitized_log[:sanitized_category].present? && validate_category(sanitized_log[:sanitized_category])
  end

  # note: the dataset contains all sorts of different strings for categories, including spaces and capital and downcased letters
  # we probably need to sanitize this data correctly by removing the spaces and dashes and downcasing it everything
  def sanitize_category(log)
    return unless log[:category].present?
    log.merge(sanitized_category: log[:category].downcase.gsub(/[\s-]/, ""))
  end

  def validate_category(category)
    categories.include?(category)
  end

  def categories
    %w[contentinjection drivebycompromise exploitpublicfacingapplication externalremoteservices hardwareadditions phishing replicationthroughremovablemedia supplychaincompromise trustedrelationship validaccounts]
  end

  def send_request(log)
    uri = URI(API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri, { "Content-Type" => "application/json", "Authorization" => API_KEY })

    request.body = {
      id: log[:id].to_i,
      asset: log[:asset_name],
      ip: log[:ip],
      category: log[:sanitized_category]
    }.to_json

    http.request(request)
  end
end