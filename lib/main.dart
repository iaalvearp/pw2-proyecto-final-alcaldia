import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'config/app_config.dart';
import 'repositories/local_procurement_repository.dart';
import 'repositories/procurement_repository.dart';
import 'repositories/sercop_procurement_repository.dart';
import 'services/sercop_api_service.dart';
import 'state/search_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<http.Client>(
          create: (_) => http.Client(),
          dispose: (_, client) => client.close(),
        ),
        Provider<SercopDataSource>(
          create: (context) => SercopApiService(context.read<http.Client>()),
        ),
        Provider<ProcurementRepository>(
          create: (context) => AppConfig.useLocalRepository
              ? LocalProcurementRepository()
              : SercopProcurementRepository(context.read<SercopDataSource>()),
        ),
        ChangeNotifierProvider<ProcurementSearchController>(
          create: (context) => ProcurementSearchController(
            context.read<ProcurementRepository>(),
          ),
        ),
      ],
      child: const AlcaldiaApp(),
    ),
  );
}
