// lib/features/backup/presentation/pages/backup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:routine/features/backup/domain/entities/backup_metadata.dart';
import 'package:routine/features/backup/presentation/bloc/backup_bloc.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          BlocBuilder<BackupBloc, BackupState>(
            buildWhen: (p, c) =>
                p.isSignedIn != c.isSignedIn || p.status != c.status,
            builder: (context, state) {
              if (!state.isSignedIn) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh backups',
                onPressed: state.status == BackupStatus.busy
                    ? null
                    : () => context
                        .read<BackupBloc>()
                        .add(const BackupListRequested()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<BackupBloc, BackupState>(
        listenWhen: (p, c) => p.message != c.message,
        listener: (context, state) {
          final msg = state.message;
          if (msg == null) return;
          final isError = state.status == BackupStatus.failure;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(msg)),
                  ],
                ),
                backgroundColor: isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.secondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
        },
        builder: (context, state) {
          final bloc = context.read<BackupBloc>();
          final busy = state.status == BackupStatus.busy;

          return AbsorbPointer(
            absorbing: busy,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // ── Account card ─────────────────────────────────
                _AccountSection(state: state, busy: busy, bloc: bloc),
                const SizedBox(height: 16),

                if (state.isSignedIn) ...[
                  // ── Active progress card (shown while busy) ───
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: busy
                        ? _ProgressCard(state: state, key: const ValueKey('progress'))
                        : const SizedBox.shrink(key: ValueKey('no-progress')),
                  ),
                  if (busy) const SizedBox(height: 16),

                  // ── Primary action ────────────────────────────
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => bloc.add(const BackupNowRequested()),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Back up now'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),

                  // ── Section header ────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Your backups',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (state.backups.isNotEmpty)
                        Text(
                          '${state.backups.length} saved',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Backup tiles ──────────────────────────────
                  if (state.backups.isEmpty && !busy)
                    const _EmptyBackupsPlaceholder()
                  else
                    ...state.backups.map(
                      (b) => _BackupTile(
                        backup: b,
                        busy: busy,
                        onRestore: () =>
                            _confirmRestore(context, bloc, b),
                        onDelete: () =>
                            _confirmDelete(context, bloc, b),
                      ),
                    ),

                  // ── Storage note ───────────────────────────────
                  if (state.backups.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _StorageNote(backups: state.backups),
                    ),
                ],

                // ── Not signed-in hint ─────────────────────────
                if (!state.isSignedIn && !busy)
                  const _SignInHint(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────

  Future<void> _confirmRestore(
    BuildContext context,
    BackupBloc bloc,
    BackupMetadata b,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.restore_rounded, size: 32),
        title: const Text('Restore this backup?'),
        content: Text(
          'This will merge ${b.entryCount} '
          '${b.entryCount == 1 ? 'entry' : 'entries'} into your diary.\n\n'
          'Newer local entries are always kept. '
          'Existing entries will only be updated if the backup version is more recent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(BackupRestoreRequested(b.driveFileId));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BackupBloc bloc,
    BackupMetadata b,
  ) async {
    final df = DateFormat.yMMMd().add_jm();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.delete_outline_rounded,
          size: 32,
          color: Theme.of(ctx).colorScheme.error,
        ),
        title: const Text('Delete this backup?'),
        content: Text(
          'The backup from ${df.format(b.createdAt.toLocal())} '
          'will be permanently removed from Google Drive. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(BackupDeleteRequested(b.driveFileId));
    }
  }
}

// ── Account section ──────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  final BackupState state;
  final bool busy;
  final BackupBloc bloc;
  const _AccountSection(
      {required this.state, required this.busy, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (state.isSignedIn) {
      return Card(
        elevation: 0,
        color: cs.primaryContainer.withOpacity(0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: cs.primary.withOpacity(0.12),
            child: Icon(Icons.cloud_done_outlined, color: cs.primary),
          ),
          title: const Text('Connected to Google Drive'),
          subtitle: const Text(
            'Backups are stored privately in your app data.',
          ),
          trailing: TextButton(
            onPressed: busy
                ? null
                : () => bloc.add(const BackupSignOutRequested()),
            child: const Text('Sign out'),
          ),
        ),
      );
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: cs.surfaceVariant,
          child: const Icon(Icons.account_circle_outlined),
        ),
        title: const Text('Not connected'),
        subtitle: const Text(
          'Sign in with Google to back up your diary to Drive.',
        ),
        trailing: FilledButton(
          onPressed: busy
              ? null
              : () => bloc.add(const BackupSignInRequested()),
          child: const Text('Sign in'),
        ),
      ),
    );
  }
}

// ── Active progress card ─────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final BackupState state;
  const _ProgressCard({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRestore = state.phase == BackupPhase.downloading ||
        state.phase == BackupPhase.writing;

    return Card(
      elevation: 0,
      color: cs.secondaryContainer.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: cs.primary,
                    // Show determinate if we have image count.
                    value: (state.phase == BackupPhase.uploadingImages ||
                                state.phase == BackupPhase.downloading) &&
                            state.hasImageProgress
                        ? state.imageProgressFraction
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isRestore ? 'Restoring backup…' : 'Backing up diary…',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Phase steps
            _PhaseStep(
              label: 'Images',
              icon: Icons.photo_library_outlined,
              isActive: state.phase == BackupPhase.uploadingImages ||
                  state.phase == BackupPhase.downloading,
              isDone: _phaseIndex(state.phase) >
                  _phaseIndex(BackupPhase.uploadingImages),
              isRestore: isRestore,
              trailing: _imageProgressText(state),
            ),
            const SizedBox(height: 6),
            _PhaseStep(
              label: isRestore ? 'Diary entries' : 'Diary entries',
              icon: Icons.book_outlined,
              isActive: state.phase == BackupPhase.uploadingEntries ||
                  state.phase == BackupPhase.writing,
              isDone: _phaseIndex(state.phase) >
                  _phaseIndex(isRestore
                      ? BackupPhase.writing
                      : BackupPhase.uploadingEntries),
              isRestore: isRestore,
            ),
            if (!isRestore) ...[
              const SizedBox(height: 6),
              _PhaseStep(
                label: 'Cleaning up old backups',
                icon: Icons.cleaning_services_outlined,
                isActive: state.phase == BackupPhase.pruning,
                isDone: state.phase == BackupPhase.idle,
                isRestore: false,
              ),
            ],

            // Image fraction bar (only during image phase with known total)
            if (state.hasImageProgress &&
                (state.phase == BackupPhase.uploadingImages ||
                    state.phase == BackupPhase.downloading)) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.imageProgressFraction,
                  minHeight: 6,
                  backgroundColor: cs.outline.withOpacity(0.15),
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${state.uploadedImages} of ${state.totalImages} images',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _phaseIndex(BackupPhase p) {
    const order = [
      BackupPhase.idle,
      BackupPhase.uploadingImages,
      BackupPhase.downloading,
      BackupPhase.uploadingEntries,
      BackupPhase.writing,
      BackupPhase.pruning,
    ];
    return order.indexOf(p);
  }

  String? _imageProgressText(BackupState state) {
    if (!state.hasImageProgress) return null;
    return '${state.uploadedImages}/${state.totalImages}';
  }
}

class _PhaseStep extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDone;
  final bool isRestore;
  final String? trailing;

  const _PhaseStep({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDone,
    required this.isRestore,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color color;
    final IconData displayIcon;

    if (isDone) {
      color = cs.primary;
      displayIcon = Icons.check_circle_rounded;
    } else if (isActive) {
      color = cs.primary;
      displayIcon = icon;
    } else {
      color = cs.onSurfaceVariant.withOpacity(0.4);
      displayIcon = icon;
    }

    return Row(
      children: [
        Icon(displayIcon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isActive || isDone
                      ? cs.onSurface
                      : cs.onSurface.withOpacity(0.4),
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
      ],
    );
  }
}

// ── Backup tile ──────────────────────────────────────────────────────

class _BackupTile extends StatelessWidget {
  final BackupMetadata backup;
  final bool busy;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _BackupTile({
    required this.backup,
    required this.busy,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat.yMMMd().add_jm();
    final sizeLabel = _formatBytes(backup.sizeBytes);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.surfaceVariant,
              child: const Icon(Icons.history_rounded, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    df.format(backup.createdAt.toLocal()),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    children: [
                      _Chip(
                          icon: Icons.article_outlined,
                          label:
                              '${backup.entryCount} ${backup.entryCount == 1 ? 'entry' : 'entries'}'),
                      if (sizeLabel.isNotEmpty)
                        _Chip(icon: Icons.storage_outlined, label: sizeLabel),
                      _Chip(
                          icon: Icons.schema_outlined,
                          label: 'v${backup.schemaVersion}'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: busy ? null : onRestore,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Restore'),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: busy ? null : cs.error,
                    size: 20,
                  ),
                  tooltip: 'Delete this backup',
                  onPressed: busy ? null : onDelete,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────

class _EmptyBackupsPlaceholder extends StatelessWidget {
  const _EmptyBackupsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 48, color: cs.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'No backups yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Back up now" to save your diary to Drive.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Sign-in hint ─────────────────────────────────────────────────────

class _SignInHint extends StatelessWidget {
  const _SignInHint();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      (Icons.lock_outline_rounded, 'Stored privately — only you can see them'),
      (Icons.wifi_off_rounded, 'Works with your diary even offline'),
      (Icons.devices_rounded, 'Restore to any device with your account'),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(e.$1, size: 18, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                      e.$2,
                      style: Theme.of(context).textTheme.bodySmall,
                    )),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Storage usage note ───────────────────────────────────────────────

class _StorageNote extends StatelessWidget {
  final List<BackupMetadata> backups;
  const _StorageNote({required this.backups});

  @override
  Widget build(BuildContext context) {
    final totalBytes = backups.fold<int>(0, (s, b) => s + b.sizeBytes);
    if (totalBytes <= 0) return const SizedBox.shrink();

    final label = _formatBytes(totalBytes);
    return Text(
      'Total Drive usage: $label  ·  Keeps the last 5 backups automatically.',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      textAlign: TextAlign.center,
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }
}