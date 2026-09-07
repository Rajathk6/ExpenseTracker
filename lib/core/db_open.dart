/// File-backed database opener (production path).
/// Tests and previews use `AppDatabase.memory()` instead — never call this there.
library;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database.dart';

Future<AppDatabase> openFileDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  return AppDatabase.file(p.join(dir.path, 'expense_tracker.sqlite'));
}
