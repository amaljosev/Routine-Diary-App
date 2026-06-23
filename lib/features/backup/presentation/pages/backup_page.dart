// lib/features/backup/presentation/pages/backup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:routine/features/backup/domain/entities/backup_metadata.dart';
import 'package:routine/features/backup/presentation/bloc/backup_bloc.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _initialFetchDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadBackups());
  }

  void _maybeLoadBackups() {
    if (!mounted || _initialFetchDone) return;
    final state = context.read<BackupBloc>().state;
    if (state.isSignedIn) {
      _initialFetchDone = true;
      context.read<BackupBloc>().add(const BackupListRequested());
    }
  }

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
                tooltip: 'Sync from Drive',
                onPressed: state.status == BackupStatus.busy
                    ? null
                    : () => context.read<BackupBloc>().add(
                        const BackupListRequested(),
                      ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<BackupBloc, BackupState>(
        listenWhen: (p, c) =>
            p.message != c.message || p.isSignedIn != c.isSignedIn,
        listener: (context, state) {
          if (state.isSignedIn && !_initialFetchDone) {
            _initialFetchDone = true;
            context.read<BackupBloc>().add(const BackupListRequested());
          }

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

          if (!isError && state.restoredCount != null) {
            context.read<DiaryBloc>().add(LoadDiaryEntries());
          }
        },
        builder: (context, state) {
          final bloc = context.read<BackupBloc>();
          final busy = state.status == BackupStatus.busy;
          final isInitialLoading =
              busy && state.backups.isEmpty && state.phase == BackupPhase.idle;

          return AbsorbPointer(
            absorbing: busy,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // ── Account card ──────────────────────────────────────
                _AccountSection(state: state, busy: busy, bloc: bloc),
                const SizedBox(height: 16),

                if (state.isSignedIn) ...[
                  // ── Active progress card ──────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SizeTransition(
                        sizeFactor: anim,
                        axisAlignment: -1,
                        child: child,
                      ),
                    ),
                    child: (busy && state.phase != BackupPhase.idle)
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ProgressCard(
                              state: state,
                              key: const ValueKey('progress'),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-progress')),
                  ),

                  // ── Main content ──────────────────────────────────
                  if (isInitialLoading)
                    const _BackupListSkeleton()
                  else if (state.backups.isEmpty)
                    _EmptyBackupsCard(
                      busy: busy,
                      onBackupNow: () => bloc.add(const BackupNowRequested()),
                    )
                  else ...[
                    // ── Latest backup hero card ────────────────────
                    _LatestBackupCard(
                      backup: state.backups.first,
                      busy: busy,
                      onRestore: () =>
                          _confirmRestore(context, bloc, state.backups.first),
                      onBackupNow: () => bloc.add(const BackupNowRequested()),
                    ),

                    // ── Previous backups ───────────────────────────
                    if (state.backups.length > 1) ...[
                      const SizedBox(height: 28),
                      _SectionHeader(
                        title: 'Previous backups',
                        count: state.backups.length - 1,
                      ),
                      const SizedBox(height: 8),
                      ...state.backups
                          .skip(1)
                          .map(
                            (b) => _PreviousBackupTile(
                              backup: b,
                              busy: busy,
                              onRestore: () =>
                                  _confirmRestore(context, bloc, b),
                              onDelete: () => _confirmDelete(context, bloc, b),
                            ),
                          ),
                    ],

                    // ── Storage note ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _StorageNote(backups: state.backups),
                    ),
                  ],
                ],

                // ── Not signed-in hint ────────────────────────────
                if (!state.isSignedIn && !busy) const _SignInHint(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────

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
    if (ok == true) bloc.add(BackupRestoreRequested(b.driveFileId));
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
    if (ok == true) bloc.add(BackupDeleteRequested(b.driveFileId));
  }
}

// ── Account section ───────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  final BackupState state;
  final bool busy;
  final BackupBloc bloc;
  const _AccountSection({
    required this.state,
    required this.busy,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (state.isSignedIn) {
      return Card(
        elevation: 0,
        color: cs.primaryContainer.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Icon(Icons.cloud_done_outlined, color: cs.primary),
          ),
          title: const Text('Connected to Google Drive'),
          subtitle: const Text('Stored privately in your app data.'),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: cs.primary.withValues(alpha: 0.6),
          child: Text(
            'G',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onPrimary,
            ),
          ),
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

// ── Progress card (redesigned) ────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final BackupState state;
  const _ProgressCard({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRestore =
        state.phase == BackupPhase.downloading ||
        state.phase == BackupPhase.writing;

    final double? fraction = state.hasImageProgress
        ? state.imageProgressFraction
        : null;
    final int? percent = fraction != null ? (fraction * 100).round() : null;

    final String phaseLabel = _phaseLabel(state.phase, isRestore);

    return Card(
      elevation: 0,
      color: cs.secondaryContainer.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            // ── Circular progress indicator ─────────────────────────
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      value: fraction,
                      backgroundColor: cs.outline.withValues(alpha: 0.15),
                      color: cs.primary,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  if (percent != null)
                    Text(
                      '$percent%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    )
                  else
                    Icon(
                      isRestore
                          ? Icons.cloud_download_outlined
                          : Icons.cloud_upload_outlined,
                      size: 22,
                      color: cs.primary,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 18),

            // ── Labels + step list ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRestore ? 'Restoring backup…' : 'Backing up diary…',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phaseLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  _PhaseStepRow(state: state, isRestore: isRestore),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(BackupPhase phase, bool isRestore) {
    switch (phase) {
      case BackupPhase.uploadingImages:
        return 'Uploading images…';
      case BackupPhase.downloading:
        return 'Downloading images…';
      case BackupPhase.uploadingEntries:
        return 'Uploading diary entries…';
      case BackupPhase.writing:
        return 'Writing diary entries…';
      case BackupPhase.pruning:
        return 'Cleaning up Drive…';
      default:
        return isRestore ? 'Preparing restore…' : 'Preparing backup…';
    }
  }
}

class _PhaseStepRow extends StatelessWidget {
  final BackupState state;
  final bool isRestore;
  const _PhaseStepRow({required this.state, required this.isRestore});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = isRestore
        ? [BackupPhase.downloading, BackupPhase.writing]
        : [
            BackupPhase.uploadingImages,
            BackupPhase.uploadingEntries,
            BackupPhase.pruning,
          ];

    return Row(
      children: steps.map((phase) {
        final idx = _phaseIndex(state.phase);
        final stepIdx = _phaseIndex(phase);
        final isDone = idx > stepIdx;
        final isActive = idx == stepIdx;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isActive
                      ? cs.primary
                      : cs.outline.withValues(alpha: 0.3),
                ),
              ),
              if (phase != steps.last)
                Expanded(
                  child: Container(
                    height: 1.5,
                    color: isDone
                        ? cs.primary
                        : cs.outline.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
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
}

// ── Latest backup hero card ───────────────────────────────────────────

class _LatestBackupCard extends StatelessWidget {
  final BackupMetadata backup;
  final bool busy;
  final VoidCallback onRestore;
  final VoidCallback onBackupNow;
  const _LatestBackupCard({
    required this.backup,
    required this.busy,
    required this.onRestore,
    required this.onBackupNow,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final local = backup.createdAt.toLocal();
    final relTime = _relativeTime(local);
    final absTime = DateFormat('MMM d, y · h:mm a').format(local);
    final isRecent = DateTime.now().difference(local).inHours < 24;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────
            Row(
              children: [
                Text(
                  'LATEST BACKUP',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isRecent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Up to date',
                          style: tt.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Time display ────────────────────────────────────────
            Text(
              relTime,
              style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              absTime,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // ── Stat boxes ──────────────────────────────────────────
            Row(
              children: [
                _StatBox(label: 'Entries', value: '${backup.entryCount}'),
                const SizedBox(width: 8),
                _StatBox(
                  label: 'Size',
                  value: backup.sizeBytes > 0
                      ? _formatBytes(backup.sizeBytes)
                      : '—',
                ),
                const SizedBox(width: 8),
                _StatBox(label: 'Version', value: 'v${backup.schemaVersion}'),
              ],
            ),
            const SizedBox(height: 14),

            // ── Action buttons ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onRestore,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Restore'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onBackupNow,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text('Back up now'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime local) {
    final diff = DateTime.now().difference(local);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && DateTime.now().day == local.day) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays == 1 ||
        (diff.inHours < 48 && DateTime.now().day != local.day)) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return DateFormat('MMM y').format(local);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ],
    );
  }
}

// ── Previous backup tile ──────────────────────────────────────────────

class _PreviousBackupTile extends StatelessWidget {
  final BackupMetadata backup;
  final bool busy;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  const _PreviousBackupTile({
    required this.backup,
    required this.busy,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final local = backup.createdAt.toLocal();
    final relTime = _relativeTime(local);
    final absTime = DateFormat('MMM d, y · h:mm a').format(local);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            // ── Avatar ────────────────────────────────────────────
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.surfaceContainerHighest,
              child: Icon(
                Icons.history_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relTime,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    absTime,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    children: [
                      _MiniChip(
                        icon: Icons.book_outlined,
                        label:
                            '${backup.entryCount} '
                            '${backup.entryCount == 1 ? 'entry' : 'entries'}',
                      ),
                      if (backup.sizeBytes > 0)
                        _MiniChip(
                          icon: Icons.storage_outlined,
                          label: _formatBytes(backup.sizeBytes),
                        ),
                      _MiniChip(
                        icon: Icons.sell_outlined,
                        label: 'v${backup.schemaVersion}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Popup menu ────────────────────────────────────────
            PopupMenuButton<_TileAction>(
              enabled: !busy,
              onSelected: (action) {
                if (action == _TileAction.restore) onRestore();
                if (action == _TileAction.delete) onDelete();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _TileAction.restore,
                  child: Row(
                    children: [
                      Icon(Icons.restore_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Restore'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _TileAction.delete,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: cs.error,
                      ),
                      const SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: cs.error)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime local) {
    final diff = DateTime.now().difference(local);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && DateTime.now().day == local.day) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1 ||
        (diff.inHours < 48 && DateTime.now().day != local.day)) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return DateFormat('MMM y').format(local);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

enum _TileAction { restore, delete }

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: cs.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────

class _BackupListSkeleton extends StatefulWidget {
  const _BackupListSkeleton();

  @override
  State<_BackupListSkeleton> createState() => _BackupListSkeletonState();
}

class _BackupListSkeletonState extends State<_BackupListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final opacity = 0.3 + _anim.value * 0.4;
        return Column(
          children: [
            // Hero card skeleton
            Container(
              height: 210,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            // Previous tiles skeleton
            ...List.generate(
              2,
              (_) => Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                height: 76,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: opacity * 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────

class _EmptyBackupsCard extends StatelessWidget {
  final bool busy;
  final VoidCallback onBackupNow;
  const _EmptyBackupsCard({required this.busy, required this.onBackupNow});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No backups yet',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              'Your diary entries will be saved privately\nto your Google Drive app data.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: busy ? null : onBackupNow,
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('Back up now'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sign-in hint ──────────────────────────────────────────────────────

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
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Storage note ──────────────────────────────────────────────────────

class _StorageNote extends StatelessWidget {
  final List<BackupMetadata> backups;
  const _StorageNote({required this.backups});

  @override
  Widget build(BuildContext context) {
    final totalBytes = backups.fold<int>(0, (s, b) => s + b.sizeBytes);
    if (totalBytes <= 0) return const SizedBox.shrink();

    return Text(
      'Drive usage: ${_formatBytes(totalBytes)} across ${backups.length} '
      '${backups.length == 1 ? 'backup' : 'backups'}',
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
