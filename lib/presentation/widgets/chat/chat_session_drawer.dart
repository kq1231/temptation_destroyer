import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/chat_session_model.dart';
import '../../providers/chat_session_provider.dart';
import '../../../core/services/sound_service.dart';

class ChatSessionDrawer extends ConsumerWidget {
  final ChatSession? currentSession;
  final Function(ChatSession) onSessionSelected;
  final Function() onNewSessionTap;
  final bool showArchived;
  final Function(bool) onShowArchivedChanged;

  final SoundService _soundService = SoundService();

  ChatSessionDrawer({
    super.key,
    required this.currentSession,
    required this.onSessionSelected,
    required this.onNewSessionTap,
    required this.showArchived,
    required this.onShowArchivedChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          _buildNewSessionButton(context),
          const Divider(),
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Center(
                    child: Text('No conversations yet'),
                  );
                }

                // Filter sessions based on archived status if needed
                final filteredSessions = showArchived
                    ? sessions
                    : sessions.where((s) => !s.isArchived).toList();

                return ListView.builder(
                  itemCount: filteredSessions.length,
                  itemBuilder: (context, index) {
                    final session = filteredSessions[index];
                    return _buildSessionTile(context, ref, session);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
          const Divider(),
          _buildDrawerFooter(context, ref),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chat Sessions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your Islamic guidance conversations',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewSessionButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add_circle),
      title: const Text('New Conversation'),
      onTap: () {
        _soundService.playSound(SoundEffect.messageSent);
        Navigator.of(context).pop(); // Close drawer
        onNewSessionTap();
      },
    );
  }

  Widget _buildSessionTile(
      BuildContext context, WidgetRef ref, ChatSession session) {
    final isSelected =
        currentSession != null && currentSession!.id == session.id;

    // Format date as "Month Day" if this year, or "Month Day, Year" if not
    final now = DateTime.now();
    final sessionDate = session.lastModified;
    final String formattedDate;

    if (sessionDate.year == now.year) {
      formattedDate = '${_getMonthName(sessionDate.month)} ${sessionDate.day}';
    } else {
      formattedDate =
          '${_getMonthName(sessionDate.month)} ${sessionDate.day}, ${sessionDate.year}';
    }

    return ListTile(
      leading: _getIconForSessionType(session.sessionType),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        formattedDate,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (session.isFavorite)
            const Icon(Icons.star, color: Colors.amber, size: 18),
          if (session.isArchived)
            const Icon(Icons.archive, color: Colors.grey, size: 18),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showSessionOptions(context, ref, session),
          ),
        ],
      ),
      selected: isSelected,
      selectedTileColor:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      onTap: () {
        _soundService.playSound(SoundEffect.messageReceived);
        Navigator.of(context).pop(); // Close drawer
        onSessionSelected(session);
      },
    );
  }

  Widget _buildDrawerFooter(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: Icon(showArchived ? Icons.visibility_off : Icons.visibility),
            label: Text(showArchived ? 'Hide Archived' : 'Show Archived'),
            onPressed: () {
              onShowArchivedChanged(!showArchived);
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            onPressed: () {
              ref.read(chatSessionsProvider.notifier).refresh();
            },
          ),
        ],
      ),
    );
  }

  void _showSessionOptions(
      BuildContext context, WidgetRef ref, ChatSession session) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, ref, session);
                },
              ),
              ListTile(
                leading: Icon(
                  session.isFavorite ? Icons.star : Icons.star_border,
                ),
                title: Text(
                  session.isFavorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(chatSessionsProvider.notifier)
                      .favoriteSession(session, !session.isFavorite);
                },
              ),
              ListTile(
                leading: Icon(
                  session.isArchived ? Icons.unarchive : Icons.archive,
                ),
                title: Text(
                  session.isArchived ? 'Unarchive' : 'Archive',
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(chatSessionsProvider.notifier)
                      .archiveSession(session, !session.isArchived);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, ref, session);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, ChatSession session) {
    final textController = TextEditingController(text: session.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Conversation'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Conversation Name',
              hintText: 'Enter a name for this conversation',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newTitle = textController.text.trim();
                if (newTitle.isNotEmpty && newTitle != session.title) {
                  final updatedSession = session.copyWith(title: newTitle);
                  ref
                      .read(chatSessionsProvider.notifier)
                      .updateSession(updatedSession);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, ChatSession session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: Text(
            'Are you sure you want to delete "${session.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(chatSessionsProvider.notifier).deleteSession(session);

                // If we're deleting the current session, need to handle that in the parent
                if (currentSession != null &&
                    currentSession!.id == session.id) {
                  // Select another session or create a new one
                  ref.read(chatSessionsProvider).whenData((sessions) {
                    if (sessions.isNotEmpty && sessions[0].id != session.id) {
                      onSessionSelected(sessions[0]);
                    } else {
                      onNewSessionTap();
                    }
                  });
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Icon _getIconForSessionType(String type) {
    if (type == ChatSessionType.normal) {
      return const Icon(Icons.chat_bubble_outline);
    } else if (type == ChatSessionType.emergency) {
      return const Icon(Icons.emergency, color: Colors.red);
    } else if (type == ChatSessionType.guided) {
      return const Icon(Icons.mosque, color: Colors.green);
    } else {
      return const Icon(Icons.chat_bubble_outline);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
