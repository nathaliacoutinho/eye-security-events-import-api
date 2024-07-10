# from rails console:
file_path = File.expand_path("~/Downloads/example_data_2.csv")
logs = CSV.read(file_path, headers: true, col_sep: ";").map(&:to_hash)
enrichment_service = AnalyticsLogsEnrichmentService.new

enriched_logs = logs.map do |log|
  enrichment_service.enrich_record(log)
end.compact

import_service = AnalyticsImportService.new
puts import_service.send_records(enriched_logs)