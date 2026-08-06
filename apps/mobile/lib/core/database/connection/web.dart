import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Opens an IndexedDB database connection for Flutter Web using drift/web.
QueryExecutor connect() {
  return WebDatabase('grahvani');
}
