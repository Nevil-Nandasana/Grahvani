import 'package:drift/drift.dart';

/// Fallback for unsupported platforms.
QueryExecutor connect() {
  throw UnsupportedError(
    'No suitable database implementation found for this platform.',
  );
}
