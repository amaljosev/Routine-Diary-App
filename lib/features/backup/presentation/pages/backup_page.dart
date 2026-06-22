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
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: BlocConsumer<BackupBloc, BackupState>(
        listenWhen: (prev, curr) => prev.message != curr.message,
        listener: (context, state) {
          final msg = state.message;
          if (msg == null) return;
          final isError = state.status == BackupStatus.failure;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: isError
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            );
        },
        builder: (context, state) {
          final bloc = context.read<BackupBloc>();
          final busy = state.status == BackupStatus.busy;

          return AbsorbPointer(
            absorbing: busy,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AccountSection(state: state, busy: busy, bloc: bloc),
                const SizedBox(height: 16),
                if (state.isSignedIn) ...[
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => bloc.add(const BackupNowRequested()),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Back up now'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => bloc.add(const BackupListRequested()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh backups'),
                  ),
                  const Divider(height: 32),
                  Text('Available backups',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (state.backups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No backups yet.')),
                    )
                  else
                    ...state.backups.map(
                      (b) => _BackupTile(
                        backup: b,
                        busy: busy,
                        onRestore: () => _confirmRestore(context, bloc, b),
                      ),
                    ),
                ],
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRestore(
      BuildContext context, BackupBloc bloc, BackupMetadata b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'This merges ${b.entryCount} entries into your diary. '
          'Newer local entries are kept. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore')),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(BackupRestoreRequested(b.driveFileId));
    }
  }
}

class _AccountSection extends StatelessWidget {
  final BackupState state;
  final bool busy;
  final BackupBloc bloc;
  const _AccountSection(
      {required this.state, required this.busy, required this.bloc});

  @override
  Widget build(BuildContext context) {
    if (state.isSignedIn) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_done_outlined),
          title: const Text('Connected to Google Drive'),
          subtitle: const Text('Backups are stored privately in app data.'),
          trailing: TextButton(
            onPressed:
                busy ? null : () => bloc.add(const BackupSignOutRequested()),
            child: const Text('Sign out'),
          ),
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_circle_outlined),
        title: const Text('Not connected'),
        subtitle: const Text('Sign in with Google to back up your diary.'),
        trailing: FilledButton(
          onPressed:
              busy ? null : () => bloc.add(const BackupSignInRequested()),
          child: const Text('Sign in'),
        ),
      ),
    );
  }
}

class _BackupTile extends StatelessWidget {
  final BackupMetadata backup;
  final bool busy;
  final VoidCallback onRestore;
  const _BackupTile(
      {required this.backup, required this.busy, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_jm();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(df.format(backup.createdAt.toLocal())),
        subtitle: Text(
            '${backup.entryCount} entries · v${backup.schemaVersion}'),
        trailing: TextButton(
          onPressed: busy ? null : onRestore,
          child: const Text('Restore'),
        ),
      ),
    );
  }
}