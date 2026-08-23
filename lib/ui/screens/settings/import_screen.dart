import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/localization/app_strings.dart';
import 'package:budasswords/providers/vault_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  _ImportState _state = _ImportState.idle;
  String? _filePath;
  int _imported = 0;
  int _skipped = 0;
  String? _error;

  Future<void> _pickAndImport() async {
    final strings = ref.read(stringsProvider);
    setState(() {
      _state = _ImportState.picking;
      _error = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: strings.importSelectFile,
    );

    if (result == null || result.files.isEmpty) {
      setState(() => _state = _ImportState.idle);
      return;
    }

    final path = result.files.single.path!;
    final file = File(path);

    if (file.lengthSync() > 10 * 1024 * 1024) {
      setState(() {
        _state = _ImportState.error;
        _error = strings.fileTooLarge;
      });
      return;
    }

    setState(() {
      _filePath = path;
      _state = _ImportState.importing;
    });

    try {
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final items = json['items'] as List<dynamic>?;
      if (items == null) {
        throw Exception(strings.invalidBitwardenFormat);
      }

      int imported = 0;
      int skipped = 0;

      for (final item in items) {
        try {
          final map = item as Map<String, dynamic>;
          final name = (map['name'] as String?) ?? 'Sin título';
          final notes = (map['notes'] as String?) ?? '';
          final type = map['type'] as int? ?? 0;

          String content;
          String? url;

          switch (type) {
            case 1: // Login
              final login = map['login'] as Map<String, dynamic>?;
              final username = (login?['username'] as String?) ?? '';
              final password = (login?['password'] as String?) ?? '';
              final uris = login?['uris'] as List<dynamic>?;
              url = uris != null && uris.isNotEmpty
                  ? (uris.first as Map<String, dynamic>)['uri'] as String?
                  : null;
              final parts = <String>[];
              if (username.isNotEmpty) parts.add('Usuario: $username');
              if (password.isNotEmpty) parts.add('Contraseña: $password');
              if (notes.isNotEmpty) parts.add('Notas: $notes');
              content = parts.join('\n');

            case 2: // Secure Note
              content = notes.isNotEmpty ? notes : '(nota vacía)';

            case 3: // Card
              final card = map['card'] as Map<String, dynamic>?;
              final holder = (card?['cardholderName'] as String?) ?? '';
              final brand = (card?['brand'] as String?) ?? '';
              final number = (card?['number'] as String?) ?? '';
              final expMonth = (card?['expMonth'] as String?) ?? '';
              final expYear = (card?['expYear'] as String?) ?? '';
              final cvv = (card?['code'] as String?) ?? '';
              final cardParts = <String>[];
              if (holder.isNotEmpty) cardParts.add('Titular: $holder');
              if (brand.isNotEmpty) cardParts.add('Marca: $brand');
              if (number.isNotEmpty) cardParts.add('Número: $number');
              if (expMonth.isNotEmpty || expYear.isNotEmpty) {
                cardParts.add('Vencimiento: $expMonth/$expYear');
              }
              if (cvv.isNotEmpty) cardParts.add('CVV: $cvv');
              if (notes.isNotEmpty) cardParts.add('Notas: $notes');
              content = cardParts.join('\n');

            case 4: // Identity
              final id = map['identity'] as Map<String, dynamic>?;
              final idParts = <String>[];
              void addId(String label, String? val) {
                if (val != null && val.isNotEmpty) idParts.add('$label: $val');
              }
              addId(
                  'Nombre',
                  [
                    id?['title'],
                    id?['firstName'],
                    id?['middleName'],
                    id?['lastName']
                  ].whereType<String>().where((s) => s.isNotEmpty).join(' '));
              addId('Compañía', id?['company']);
              addId('Email', id?['email']);
              addId('Teléfono', id?['phone']);
              addId('Documento', id?['ssn'] ?? id?['passportNumber']);
              addId(
                  'Dirección',
                  [
                    id?['address1'],
                    id?['address2'],
                    id?['city'],
                    id?['state'],
                    id?['postalCode'],
                    id?['country']
                  ].whereType<String>().where((s) => s.isNotEmpty).join(', '));
              if (notes.isNotEmpty) idParts.add('Notas: $notes');
              content = idParts.join('\n');

            default:
              content = notes.isNotEmpty ? notes : '(entrada vacía)';
          }

          await ref.read(vaultNotifierProvider.notifier).createEntry(
                title: name,
                url: url,
                content: content,
              );
          imported++;
        } catch (_) {
          skipped++;
        }
      }

      setState(() {
        _imported = imported;
        _skipped = skipped;
        _state = _ImportState.done;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _state = _ImportState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                // Centered Header aligned with content
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 24, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: strings.back,
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          strings.importTitle,
                          style: GoogleFonts.newsreader(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InfoCard(strings: strings).animate().fadeIn(),
                        const Gap(20),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _state == _ImportState.importing ? null : _pickAndImport,
                            icon: const Icon(Icons.file_open_outlined, size: 20),
                            label: Text(
                              _state == _ImportState.done
                                  ? strings.importCompleted
                                  : strings.importSelectFile,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 150.ms),
                        if (_state != _ImportState.idle) ...[
                          const Gap(24),
                          _buildBody(strings),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppStrings strings) {
    switch (_state) {
      case _ImportState.idle:
        return const SizedBox.shrink();

      case _ImportState.picking:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        );

      case _ImportState.importing:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
                const Gap(16),
                Text(
                  strings.importingProgress,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (_filePath != null) ...[
                  const Gap(8),
                  Text(
                    _filePath!.split(Platform.pathSeparator).last,
                    style: const TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );

      case _ImportState.done:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 54,
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const Gap(12),
              Text(
                strings.importSuccess(_imported),
                style: GoogleFonts.newsreader(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_skipped > 0) ...[
                const Gap(8),
                Text(
                  strings.importSkipped(_skipped),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ).animate().fadeIn();

      case _ImportState.error:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 44,
              ),
              const Gap(12),
              Text(
                _error ?? strings.error,
                style: const TextStyle(color: AppColors.danger, fontSize: 13.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn();
    }
  }
}

enum _ImportState { idle, picking, importing, done, error }

class _InfoCard extends StatelessWidget {
  final AppStrings strings;

  const _InfoCard({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, color: AppColors.accent, size: 22),
              const Gap(10),
              Text(
                strings.importHowTo,
                style: GoogleFonts.newsreader(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Gap(18),
          _step('1', strings.importStep1),
          const Gap(12),
          _step('2', strings.importStep2),
          const Gap(12),
          _step('3', strings.importStep3),
          const Gap(12),
          _step('4', strings.importStep4),
          const Gap(18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentDim.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                const Gap(8),
                Expanded(
                  child: Text(
                    strings.importWarning,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String n, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accentDim,
            shape: BoxShape.circle,
          ),
          child: Text(
            n,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Gap(12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
