import 'package:drift/drift.dart';

import 'unsupported.dart'
    if (dart.library.ffi) 'native.dart'
    if (dart.library.js_interop) 'web.dart'
    if (dart.library.html) 'web.dart';

/// Opens platform-appropriate database connection.
QueryExecutor openConnection() => connect();
