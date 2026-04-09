import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '/screens/home_screen.dart';
import '/screens/main_screen_agent.dart';
import '/services/api_manager.dart';
import '/theme/style.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _id = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _id.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_id.text.isEmpty) {
      EasyLoading.showToast("L'identifiant est requis.");
      return;
    }
    if (_pass.text.isEmpty) {
      EasyLoading.showToast("Le mot de passe est requis.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiManager().login(uMatricule: _id.text, uPass: _pass.text);
      setState(() => _isLoading = false);

      if (result is String) {
        EasyLoading.showInfo(result);
      } else {
        if (result.role == 'resident') {
          Get.offAll(() => const HomeScreen());
        } else if (result.role == 'agent') {
          Get.offAll(() => const MainScreenAgent());
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      EasyLoading.showError("Erreur de connexion.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/abstract.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.7),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F4ACF), Color(0xFF0B2D7A)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text("S", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))),
              ),
              const SizedBox(height: 12),
              const Text("Salama Access", style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 28, fontWeight: FontWeight.w900, fontFamily: "Ubuntu")),
              const SizedBox(height: 30),
              _modernField(controller: _id, hint: "Matricule ou e-mail", icon: Icons.person_outline),
              const SizedBox(height: 20),
              _modernField(
                controller: _pass, hint: "Mot de passe", icon: Icons.lock_outline, obscure: _obscure,
                suffix: GestureDetector(onTap: () => setState(() => _obscure = !_obscure), child: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.black45)),
              ),
              const SizedBox(height: 32),
              _loginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, Widget? suffix}) {
    return Column(children: [
      Row(children: [
        Icon(icon, color: const Color(0xFF0B2D7A), size: 20),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: controller, obscureText: obscure, decoration: InputDecoration(hintText: hint, border: InputBorder.none, isDense: true, suffixIcon: suffix))),
      ]),
      const SizedBox(height: 8),
      Container(height: 1.5, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black12, const Color(0xFF0F4ACF)]))),
    ]);
  }

  Widget _loginButton() {
    return Container(
      width: double.infinity, height: 52,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [Color(0xFF0B2D7A), Color(0xFF0F4ACF)])),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _login,
          child: Center(child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Se connecter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }
}
