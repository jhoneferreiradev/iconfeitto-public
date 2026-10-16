import 'package:material_ui/material_ui.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class IConfeittoApp extends StatelessWidget {
  const IConfeittoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IConfeitto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('pt', 'BR'), // português
      ],
    );
  }
}
