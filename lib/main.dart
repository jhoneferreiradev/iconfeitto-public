import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'shared/data/app_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppRepository.instance.initialize();
  runApp(const ConfeitariaApp());
}
