import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taxenew/screens/auth/login2.dart';
import '/controllers/data_controller.dart';
import '/screens/home_screen.dart';
import '/screens/main_screen_agent.dart';
import '/utils/controllers.dart';
import '/utils/translations.dart';
import '/screens/auth/login.dart';
import '/theme/style.dart';
import 'controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(AuthController());
  Get.put(DataController());
  configEasyLoading();
  runApp(const MyApp());
}

void configEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..loadingStyle = EasyLoadingStyle.custom
    ..radius = 12.0
    ..backgroundColor = Colors.white
    ..textColor = Colors.black
    ..indicatorColor = primaryColor
    ..maskColor = Colors.black.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false
    ..toastPosition = EasyLoadingToastPosition.bottom;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Widget> _startupFuture;
  final storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _startupFuture = _initApp();
  }

  Future<Widget> _initApp() async {
    try {
      await authController.refreshUser();
      if (authController.user.value != null) {
        final role = authController.user.value!.role;
        if (role == 'resident') {
          return const HomeScreen();
        } else if (role == 'agent') {
          return const MainScreenAgent();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur initApp: $e");
      }
    }
    return const Login2();
  }

  @override
  Widget build(BuildContext context) {
    String savedLang = storage.read('language') ?? 'fr';
    Locale initialLocale = Locale(savedLang);

    return GetMaterialApp(
      title: 'Salama Access',
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('fr'),
      theme: ThemeData(
        primaryColor: primaryColor,
        primarySwatch: primaryMaterialColor,
        scaffoldBackgroundColor: Colors.grey.shade100,
        fontFamily: 'Ubuntu',
        useMaterial3: true,
      ),
      home: FutureBuilder<Widget>(
        future: _startupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F4ACF), Color(0xFF0B2D7A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          "S",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      color: Color(0xFF0B2D7A),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Erreur : ${snapshot.error}'),
              ),
            );
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
}
