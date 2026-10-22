/// The file format a user can export their data as.
enum ExportFormat {
  /// One row per day, spreadsheet-friendly. Metrics and check-in statuses
  /// only.
  csv(fileExtension: 'csv', mimeType: 'text/csv'),

  /// Everything, in a versioned shape a future import can restore from.
  json(fileExtension: 'json', mimeType: 'application/json');

  ExportFormat({required this.fileExtension, required this.mimeType});

  /// The file name extension, without the dot.
  final String fileExtension;

  /// The MIME type handed to the share sheet.
  final String mimeType;
}
