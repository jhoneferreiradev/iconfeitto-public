import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'shared/data/app_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite não tem implementação nativa em desktop; usa a versão FFI.
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await AppRepository.instance.initialize();
  runApp(const ConfeitariaApp());
}
