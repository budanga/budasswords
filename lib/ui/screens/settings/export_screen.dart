import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/localization/app_strings.dart';
import 'package:budasswords/domain/models/vault_entry.dart';
import 'package:budasswords/providers/vault_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  _ExportState _state = _ExportState.idle;
  String? _savedPath;
  int _exportedCount = 0;
  String? _error;

  Future<void> _exportVault() async {
    final strings = ref.read(stringsProvider);
    final entriesAsync = ref.read(vaultEntriesProvider);

    final entries = entriesAsync.valueOrNull ?? [];
    if (entries.isEmpty) {
      setState(() {
        _state = _ExportState.error;
        _error = strings.exportEmpty;
      });
      return;
    }

    setState(() {
      _state = _ExportState.picking;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
      final defaultFileName = 'budasswords_backup_$dateStr.json';

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: strings.exportSelectLocation,
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (savePath == null) {
        setState(() => _state = _ExportState.idle);
        return;
      }

      setState(() => _state = _ExportState.exporting);

      // Build standard JSON payload matching Bitwarden export compatibility
      final exportData = {
        'encrypted': false,
        'format': 'budasswords-v1',
        'exportedAt': now.toIso8601String(),
        'items': entries.map((e) {
          int typeInt;
          switch (e.category) {
            case EntryCategory.login:
              typeInt = 1;
            case EntryCategory.note:
              typeInt = 2;
            case EntryCategory.card:
              typeInt = 3;
          }

          return {
            'id': e.id,
            'name': e.title,
            'type': typeInt,
            'notes': e.cleanContent,
            'login': e.category == EntryCategory.login
                ? {
                    'uris': e.url != null && e.url!.isNotEmpty
                        ? [{'uri': e.url}]
                        : [],
                    'password': e.cleanContent,
                  }
                : null,
            'createdAt': e.createdAt.toIso8601String(),
            'updatedAt': e.updatedAt.toIso8601String(),
          };
        }).toList(),
      };

      final jsonContent = const JsonEncoder.withIndent('  ').convert(exportData);
      final file = File(savePath);
      await file.writeAsString(jsonContent, encoding: utf8);

      setState(() {
        _state = _ExportState.done;
        _savedPath = savePath;
        _exportedCount = entries.length;
      });
    } catch (e) {
      setState(() {
        _state = _ExportState.error;
        _error = e.toString();
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
                // Header
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
                          strings.exportTitle,
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
                        _ExportInfoCard(strings: strings).animate().fadeIn(),
                        const Gap(20),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _state == _ExportState.exporting ? null : _exportVault,
                            icon: const Icon(Icons.download_outlined, size: 20),
                            label: Text(
                              strings.exportSelectLocation,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 150.ms),
                        if (_state != _ExportState.idle) ...[
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
      case _ExportState.idle:
        return const SizedBox.shrink();

      case _ExportState.picking:
      case _ExportState.exporting:
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
                  strings.exportingProgress,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );

      case _ExportState.done:
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
                strings.exportSuccess(_exportedCount),
                style: GoogleFonts.newsreader(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (_savedPath != null) ...[
                const Gap(10),
                Text(
                  _savedPath!,
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ).animate().fadeIn();

      case _ExportState.error:
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

enum _ExportState { idle, picking, exporting, done, error }

class _ExportInfoCard extends StatelessWidget {
  final AppStrings strings;

  const _ExportInfoCard({required this.strings});

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
              const Icon(Icons.lock_open_outlined, color: AppColors.warning, size: 22),
              const Gap(10),
              Text(
                strings.exportHowTo,
                style: GoogleFonts.newsreader(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                const Gap(10),
                Expanded(
                  child: Text(
                    strings.exportWarning,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
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
}
