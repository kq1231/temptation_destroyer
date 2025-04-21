import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/chat_session_model.dart';
import '../../providers/chat_session_provider.dart';
import '../../widgets/chat/new_chat_session_dialog.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../../core/services/sound_service.dart';
import 'ai_guidance_screen.dart';

class ChatSessionsScreen extends ConsumerStatefulWidget {
  static const routeName = '/chat-sessions';

  const ChatSessionsScreen({super.key});

  @override
  ConsumerState<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends ConsumerState<ChatSessionsScreen> {
  bool _showArchived = false;
  final SoundService _soundService = SoundService();

  @override
  void initState() {
    super.initState();
    // Initialize session data
    Future.microtask(() => ref.read(chatSessionsProvider.notifier).refresh());
  }

  void _createNewSession() {
    showDialog(
      context: context,
      builder: (context) => NewChatSessionDialog(
        onSessionCreated: (session) {
          _openChatSession(session);
        },
      ),
    );
  }

  void _openChatSession(ChatSession session) {
    _soundService.playSound(SoundEffect.messageReceived);
    Navigator.pushNamed(
      context,
      AIGuidanceScreen.routeName,
      arguments: session,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Sessions'),
        actions: [
          // Filter archived button
          IconButton(
            icon: Icon(_showArchived ? Icons.visibility_off : Icons.visibility),
            tooltip: _showArchived ? 'Hide Archived' : 'Show Archived',
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
              });
            },
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/ai-settings');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewSession,
        tooltip: 'New Conversation',
        child: const Icon(Icons.add),
      ),
      body: _buildSessionsList(),
    );
  }

  Widget _buildSessionsList() {
    return ref.watch(chatSessionsProvider).when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return _buildEmptyState();
            }

            // Filter sessions based on archived status
            final filteredSessions = _showArchived
                ? sessions
                : sessions.where((s) => !s.isArchived).toList();

            if (filteredSessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.archive,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No active conversations',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All conversations are archived',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('New Conversation'),
                      onPressed: _createNewSession,
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: filteredSessions.length,
              itemBuilder: (context, index) {
                final session = filteredSessions[index];
                return _buildSessionCard(session);
              },
            );
          },
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading sessions: $error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () {
                    ref.read(chatSessionsProvider.notifier).refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.black26,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Conversations Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a new conversation to get Islamic guidance',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('New Conversation'),
            onPressed: _createNewSession,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(ChatSession session) {
    // Format date
    final now = DateTime.now();
    final sessionDate = session.lastModified;
    final String formattedDate;

    if (sessionDate.year == now.year) {
      formattedDate = '${_getMonthName(sessionDate.month)} ${sessionDate.day}';
    } else {
      formattedDate =
          '${_getMonthName(sessionDate.month)} ${sessionDate.day}, ${sessionDate.year}';
    }

    Icon sessionIcon;
    Color cardColor;

    switch (session.sessionType) {
      case ChatSessionType.normal:
        sessionIcon = const Icon(Icons.chat_bubble_outline);
        cardColor = Theme.of(context).colorScheme.secondaryContainer;
        break;
      case ChatSessionType.emergency:
        sessionIcon = const Icon(Icons.emergency, color: Colors.red);
        cardColor = Colors.red.shade50;
        break;
      case ChatSessionType.guided:
        sessionIcon = const Icon(Icons.mosque, color: Colors.green);
        cardColor = Colors.green.shade50;
        break;
    }

    return Card(
      color: cardColor,
      elevation: 2,
      child: InkWell(
        onTap: () => _openChatSession(session),
        onLongPress: () => _showSessionOptions(context, session),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  sessionIcon,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (session.isFavorite)
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                      if (session.isArchived)
                        const Icon(Icons.archive, color: Colors.grey, size: 18),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showSessionOptions(context, session),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                session.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              if (session.tags.isNotEmpty) const SizedBox(height: 4),
              if (session.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: session.tags
                      .take(2)
                      .map((tag) => Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionOptions(BuildContext context, ChatSession session) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Open Conversation'),
                onTap: () {
                  Navigator.pop(context);
                  _openChatSession(session);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, session);
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
                  _showDeleteConfirmation(context, session);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, ChatSession session) {
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

  void _showDeleteConfirmation(BuildContext context, ChatSession session) {
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
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
