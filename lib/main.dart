import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/service/analytics_batch_service.dart';
import 'package:rescu/service/analytics_impression_service.dart';

import 'app_config.dart';
import 'repository/deal_repo.dart';
import 'repository/order_repo.dart';
import 'repository/store_repo.dart';
import 'routes/routes.dart';
import 'service/analytics_service.dart';
import 'service/cart_service.dart';
import 'service/fake_api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const RescuApp());
}

Future<void> initDependencies() async {
  await Get.putAsync(() => FakeApiService().init(), permanent: true);
  Get.put(AnalyticsService(), permanent: true);
  Get.put(CartService(), permanent: true);
  Get.put<AnalyticsService>(
    AnalyticsService(),
    permanent: true,
  );

  Get.put<AnalyticsImpressionService>(
    AnalyticsImpressionService(
      analytics: Get.find<AnalyticsService>(),
    ),
    permanent: true,
  );

  Get.put<AnalyticsBatchService>(
    AnalyticsBatchService(
      analytics: Get.find<AnalyticsService>(),
      api: Get.find<FakeApiService>(),
    ),
    permanent: true,
  );
  Get.lazyPut(() => DealRepo(api: Get.find()), fenix: true);
  Get.lazyPut(() => StoreRepo(api: Get.find()), fenix: true);
  Get.lazyPut(() => OrderRepo(api: Get.find()), fenix: true);
}

class RescuApp extends StatelessWidget {
  const RescuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppConfig.theme,
      initialRoute: Routes.home,
      getPages: Routes.pages,
    );
  }
}
