import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reserved for future startup initialization such as storage or player setup.
  runApp(const ProviderScope(child: AnimeStreamApp()));
}
