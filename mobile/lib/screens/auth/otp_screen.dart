import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class OtpScreen extends StatefulWidget {
  final String telephone;
  const OtpScreen({super.key, required this.telephone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes   = List.generate(6, (_) => FocusNode());

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onChanged(int idx, String val) {
    if (val.length == 1 && idx < 5) {
      _focusNodes[idx + 1].requestFocus();
    }
    if (_code.length == 6) _verifier();
  }

  Future<void> _verifier() async {
    if (_code.length < 6) return;
    final auth = context.read<AuthProvider>();
    try {
      await auth.verifierOtp(widget.telephone, _code);
      if (mounted) context.go('/accueil');
    } on Exception catch (e) {
      if (mounted) {
        for (final c in _controllers) c.clear();
        _focusNodes[0].requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text('Code de vérification', style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white)),
              const SizedBox(height: 8),
              Text('Code envoyé au ${widget.telephone}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.white.withOpacity(0.7))),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (i) => SizedBox(
                        width: 44,
                        child: TextFormField(
                          controller:      _controllers[i],
                          focusNode:       _focusNodes[i],
                          keyboardType:    TextInputType.number,
                          textAlign:       TextAlign.center,
                          maxLength:       1,
                          style:           GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.navy),
                          decoration:      const InputDecoration(counterText: ''),
                          onChanged:       (v) => _onChanged(i, v),
                        ),
                      )),
                    ),
                    const SizedBox(height: 24),
                    if (auth.charge)
                      const CircularProgressIndicator(color: AppColors.navy)
                    else
                      ElevatedButton(
                        onPressed: _code.length == 6 ? _verifier : null,
                        child: const Text('Valider'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text('Modifier le numéro', style: GoogleFonts.plusJakartaSans(color: AppColors.white.withOpacity(0.7))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
