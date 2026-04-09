import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '/screens/home_screen.dart';
import '/screens/main_screen_agent.dart';
import '/services/api_manager.dart';

class Login2 extends StatefulWidget {
  const Login2({super.key});

  @override
  State<Login2> createState() => _Login2State();
}

class _Login2State extends State<Login2> {
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
            // 🌤️ Background
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/images/abstract.jpg"),
                  fit: BoxFit.cover
                )
              ),
            ),


            // 🧊 CONTENT RESPONSIVE
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


  // 🧊 Glass Card
  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.85),
                Colors.white.withOpacity(0.55),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F4ACF), Color(0xFF0B2D7A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F4ACF).withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "S",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ),
                ),
              ),

              const Text(
                "Salama Access",
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontFamily: "Ubuntu",
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Veuillez entrer vos identifiants(code ou email et mot de passe) pour vous connecter.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black26,fontFamily: "Ubuntu", fontSize: 12.0),
              ),

              const SizedBox(height: 20.0),

              _modernField(
                controller: _id,
                hint: "Matricule ou e-mail",
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 20),

              _modernField(
                controller: _pass,
                hint: "Mot de passe",
                icon: Icons.lock_outline,
                obscure: _obscure,
                suffix: GestureDetector(
                  onTap: () =>
                      setState(() => _obscure = !_obscure), child: Icon(
                    _obscure
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.black45,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              _loginButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ INPUT LINE MODERNE
  Widget _modernField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:const Color(0xFF0B2D7A),
              size: 20,
            ),
            const SizedBox(width: 10),

            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscure,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Colors.black38,
                    height: 1.2,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: suffix,
                  suffixIconConstraints: const BoxConstraints(
                    minHeight: 24,
                    minWidth: 24,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.1),
                const Color(0xFF0F4ACF),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🔥 BUTTON
  Widget _loginButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B2D7A),
            Color(0xFF0F4ACF)
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4ACF).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isLoading ? null : _login,
          child: Center(
            child: _isLoading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
                  "Se connecter",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}