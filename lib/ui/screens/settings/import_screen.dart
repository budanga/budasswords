import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gap/gap.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/providers/vault_provider.dart';

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
    setState(() {
      _state = _ImportState.picking;
      _error = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Seleccioná tu exportación de Bitwarden',
    );

    if (result == null || result.files.isEmpty) {
      setState(() => _state = _ImportState.idle);
      return;
    }

    final path = result.files.single.path!;
    setState(() {
      _filePath = path;
      _state = _ImportState.importing;
    });

    try {
      final raw = await File(path).readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final items = json['items'] as List<dynamic>?;
      if (items == null) {
        throw Exception('El archivo no tiene el formato correcto de Bitwarden.');
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
              final holder   = (card?['cardholderName'] as String?) ?? '';
              final brand    = (card?['brand'] as String?) ?? '';
              final number   = (card?['number'] as String?) ?? '';
              final expMonth = (card?['expMonth'] as String?) ?? '';
              final expYear  = (card?['expYear'] as String?) ?? '';
              final cvv      = (card?['code'] as String?) ?? '';
              final cardParts = <String>[];
              if (holder.isNotEmpty)   cardParts.add('Titular: $holder');
              if (brand.isNotEmpty)    cardParts.add('Marca: $brand');
              if (number.isNotEmpty)   cardParts.add('Número: $number');
              if (expMonth.isNotEmpty || expYear.isNotEmpty)
                cardParts.add('Vencimiento: $expMonth/$expYear');
              if (cvv.isNotEmpty)      cardParts.add('CVV: $cvv');
              if (notes.isNotEmpty)    cardParts.add('Notas: $notes');
              content = cardParts.join('\n');

            case 4: // Identity
              final id = map['identity'] as Map<String, dynamic>?;
              final idParts = <String>[];
              void addId(String label, String? val) {
                if (val != null && val.isNotEmpty) idParts.add('$label: $val');
              }
              addId('Nombre', [
                id?['title'], id?['firstName'],
                id?['middleName'], id?['lastName']
              ].whereType<String>().where((s) => s.isNotEmpty).join(' '));
              addId('Empresa', id?['company']);
              addId('Email', id?['email']);
              addId('Teléfono', id?['phone']);
              addId('DNI/Pasaporte', id?['ssn'] ?? id?['passportNumber']);
              addId('Dirección', [
                id?['address1'], id?['address2'],
                id?['city'], id?['state'], id?['postalCode'], id?['country']
              ].whereType<String>().where((s) => s.isNotEmpty).join(', '));
              if (notes.isNotEmpty) idParts.add('Notas: $notes');
              content = idParts.join('\n');

            default:
              // Unknown type — save notes as fallback
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
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('Importar desde Bitwarden')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            _InfoCard().animate().fadeIn(),
            const Gap(24),

            // Status area
            Expanded(child: _buildBody()),

            // Button
            if (_state == _ImportState.idle ||
                _state == _ImportState.error ||
                _state == _ImportState.done)
              FilledButton.icon(
                onPressed: _state == _ImportState.done ? null : _pickAndImport,
                icon: const Icon(Icons.file_open_outlined),
                label: Text(
                  _state == _ImportState.done
                      ? 'Importación completada'
                      : 'Seleccionar archivo JSON',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ImportState.idle:
        return const SizedBox.shrink();

      case _ImportState.picking:
        return const Center(child: CircularProgressIndicator());

      case _ImportState.importing:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const Gap(16),
              Text(
                'Importando entradas...',
                style: TextStyle(color: AppColors.textSecondary),
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
        );

      case _ImportState.done:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 72)
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut),
              const Gap(20),
              Text(
                '$_imported contraseñas importadas',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_skipped > 0) ...[
                const Gap(8),
                Text(
                  '$_skipped entradas no se pudieron importar.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ).animate().fadeIn(),
        );

      case _ImportState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 56),
              const Gap(16),
              Text(
                _error ?? 'Error desconocido',
                style: const TextStyle(color: AppColors.danger),
                textAlign: TextAlign.center,
              ),
            ],
          ).animate().fadeIn(),
        );
    }
  }
}

enum _ImportState { idle, picking, importing, done, error }

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withAlpha(60)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.accent, size: 20),
              const Gap(8),
              const Text(
                'Cómo exportar desde Bitwarden',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Gap(10),
          _step('1', 'Abrí Bitwarden en tu navegador o app.'),
          _step('2', 'Andá a Herramientas → Exportar bóveda.'),
          _step('3', 'Elegí formato JSON (sin cifrar).'),
          _step('4', 'Guardá el archivo y seleccionalo acá.'),
          const Gap(8),
          const Text(
            '⚠ El archivo JSON contiene tus contraseñas en texto plano. Eliminalo cuando termines.',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
