import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/constants/app_constants.dart';
import 'package:routine/core/services/export_diary_service.dart';
import 'package:routine/core/utils/share_util.dart';
import 'package:routine/core/version/app_version.dart';
import 'package:routine/features/app_lock/presentation/pages/app_lock_settings_page.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/settings/presentation/pages/contact_us.dart';
import 'package:routine/features/settings/presentation/pages/help_screen.dart';
import 'package:routine/features/settings/presentation/pages/theme/theme_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // true while the PDF is being generated / saved
  bool _isExporting = false;

  // ── Export handler ─────────────────────────────────────────────────────────

  Future<void> _onExportDiary() async {
    // Load entries fresh from the DiaryBloc.
    final diaryBloc = context.read<DiaryBloc>();
    final entries = diaryBloc.state.entries;

    if (entries.isEmpty) {
      _showSnackbar(
        message: 'No diary entries to export.',
        icon: Icons.info_outline,
        isError: false,
      );
      return;
    }

    // Show a confirmation dialog before starting.
    final confirmed = await _showExportConfirmDialog(entries.length);
    if (!confirmed || !mounted) return;

    setState(() => _isExporting = true);

    try {
      final savedPath = await DiaryExportService.exportToPdf(entries);

      if (!mounted) return;
      _showExportSuccessSheet(savedPath);
    } catch (e) {
      log('DiaryExport error: $e');
      if (!mounted) return;
      _showSnackbar(
        message: e.toString().replaceFirst('Exception: ', ''),
        icon: Icons.error_outline,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Confirm dialog ─────────────────────────────────────────────────────────

  Future<bool> _showExportConfirmDialog(int count) async {
    final theme = Theme.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.picture_as_pdf_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Export Diary'),
              ],
            ),
            content: Text(
              'This will export all $count ${count == 1 ? 'entry' : 'entries'} '
              'to a single PDF file and save it to your Downloads folder.',
              style: theme.textTheme.bodyMedium,
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Success bottom sheet ───────────────────────────────────────────────────

  void _showExportSuccessSheet(String filePath) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Success icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'PDF Saved!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your diary has been saved to:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),

            // File path chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined,
                      size: 16,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filePath,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Done button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Snackbar helper ────────────────────────────────────────────────────────

  void _showSnackbar({
    required String message,
    required IconData icon,
    required bool isError,
  }) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        backgroundColor:
            isError ? theme.colorScheme.error : theme.colorScheme.primary,
        content: Row(
          children: [
            Icon(icon,
                color: isError
                    ? theme.colorScheme.onError
                    : theme.colorScheme.onPrimary,
                size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            /// Top Logo + Title
            SliverToBoxAdapter(
              child: Column(
                spacing: 20,
                children: [
                  Image.asset(
                    'assets/icons/routine_icon.png',
                    height: 80,
                    width: 80,
                  ),
                  Text(
                    'Routine: Diary App',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            /// Main List Section
            SliverList(
              delegate: SliverChildListDelegate([
                // ── SETTINGS ──────────────────────────────────────────────
                CupertinoListSection.insetGrouped(
                  header: Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.color_lens_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: const Text('Theme'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ThemeSwitcherScreen(),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.lock_outline_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: const Text('Diary Lock'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AppLockSettingsPage(),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── DATA ──────────────────────────────────────────────────
                CupertinoListSection.insetGrouped(
                  header: Text(
                    'Data',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  children: [
                    // Export diary entry — the new button
                    ListTile(
                      leading: _isExporting
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Theme.of(context).primaryColor,
                              ),
                            )
                          : Icon(
                              Icons.picture_as_pdf_outlined,
                              color: Theme.of(context).primaryColor,
                            ),
                      title: const Text('Export Diary to PDF'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      subtitle: Text(
                        'Save all entries as a PDF to your Downloads folder',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                      trailing: _isExporting
                          ? null
                          : const CupertinoListTileChevron(),
                      onTap: _isExporting ? null : _onExportDiary,
                    ),
                  ],
                ),

                // ── APP INFORMATION ───────────────────────────────────────
                CupertinoListSection.insetGrouped(
                  header: Text(
                    'App',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  children: [
                    ListTile(
                      leading: Icon(
                        color: Theme.of(context).primaryColor,
                        Icons.support_agent,
                      ),
                      title: const Text('Help'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HelpScreen(),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        color: Theme.of(context).primaryColor,
                        Icons.shield_outlined,
                      ),
                      title: const Text('Privacy Policy'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: () async => await _launchPrivacyPolicy(context),
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashFactory: NoSplash.splashFactory,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        leading: Icon(
                          color: Theme.of(context).primaryColor,
                          Icons.info_outline,
                        ),
                        title: Text(
                          'About this app',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        trailing: const CupertinoListTileChevron(),
                        childrenPadding: const EdgeInsets.all(12),
                        children: [_buildAboutContent(context)],
                      ),
                    ),
                  ],
                ),

                // ── ENGAGEMENT ────────────────────────────────────────────
                CupertinoListSection.insetGrouped(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  header: Text(
                    'Engagement',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.share_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: const Text('Share'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: () async => await ShareUtils.shareApp(),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.star_border,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: const Text('Rate app'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: () async =>
                          await openUrl(context, AppConstants.playStoreUrl),
                    ),
                  ],
                ),

                // ── SUPPORT ───────────────────────────────────────────────
                CupertinoListSection.insetGrouped(
                  header: Text(
                    'Support',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  children: [
                    ListTile(
                      leading: Icon(
                        CupertinoIcons.mail,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: const Text('Contact us'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: () async => showModernSupportSheet(context),
                    ),
                  ],
                ),

                // ── APPS ──────────────────────────────────────────────────
                CupertinoListSection.insetGrouped(
                  header: Text(
                    'Try our new app',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  children: [
                    ListTile(
                      leading: Card(
                        child: Image.asset('assets/icons/pursuit_icon.png'),
                      ),
                      title: const Text('Pursuit: Habit tracker'),
                      titleTextStyle: Theme.of(context).textTheme.titleMedium,
                      subtitle: const Text('Your daily growth partner'),
                      subtitleTextStyle:
                          Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: () async =>
                          openUrl(context, AppConstants.pursuitUrl),
                    ),
                  ],
                ),
              ]),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildAboutContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Routine: Diary App',
          style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          '''Routine is a simple and private diary application designed to help you capture your daily thoughts, experiences, and reflections in one secure place.

With a clean and distraction-free interface, Routine makes journaling easy and consistent. Whether you want to record memories, track personal growth, or simply express your thoughts, Routine helps you build a meaningful daily writing habit.

Write daily. Reflect deeply. Grow consistently.''',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text('Version: ${AppVersion.version}', style: textTheme.bodyMedium),
        const SizedBox(height: 12),
        Text('Developed by Amal Jose', style: textTheme.bodyMedium),
      ],
    );
  }

  Future<void> _launchPrivacyPolicy(BuildContext context) async {
    final Uri url = Uri.parse(
      'https://amaljosev.github.io/Routine-privacy-policy/',
    );
    if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sorry we are facing an issue')),
        );
      } else {
        log('not mounted');
      }
    }
  }

  Future<void> openUrl(BuildContext context, String uri) async {
    final Uri url = Uri.parse(uri);
    if (!await launchUrl(url, mode: LaunchMode.platformDefault) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sorry we are facing an issue')),
      );
    }
  }

  void showModernSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ContactUsSheet(),
    );
  }
}