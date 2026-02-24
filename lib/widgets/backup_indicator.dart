import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../services/storage_service.dart';

class BackupIndicator extends StatefulWidget {
  const BackupIndicator({super.key});

  @override
  State<BackupIndicator> createState() => _BackupIndicatorState();
}

class _BackupIndicatorState extends State<BackupIndicator> {
  DateTime? _lastBackupTime;
  // Remove unused _isLoading field

  @override
  void initState() {
    super.initState();
    _loadLastBackupTime();
  }

  Future<void> _loadLastBackupTime() async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    if (transactionProvider.currentUserId != null) {
      final metadata = await StorageService.getBackupMetadata(transactionProvider.currentUserId!);
      if (metadata != null && metadata.containsKey('last_updated')) {
        setState(() {
          _lastBackupTime = DateTime.parse(metadata['last_updated']);
        });
      }
    }
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton(
      tooltip: 'Backup Status',
      icon: Icon(
        Icons.backup,
        color: _lastBackupTime == null 
            ? colorScheme.onSurface.withValues(alpha: 0.5)
            : colorScheme.primary,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Backup Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (_lastBackupTime != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text('Last backup: ${_getTimeAgo(_lastBackupTime!)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Auto-backups every 7 days',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ] else ...[
                const Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text('No backup yet'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}