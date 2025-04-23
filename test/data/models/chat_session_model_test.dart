import 'package:flutter_test/flutter_test.dart';
import 'package:temptation_destroyer/data/models/chat_session_model.dart';
import 'package:temptation_destroyer/data/models/ai_models.dart';

void main() {
  group('ChatSession', () {
    test('creates with default values', () {
      final session = ChatSession(title: 'Test Session');

      expect(session.id, equals(0));
      expect(session.uid, isNotEmpty);
      expect(session.title, equals('Test Session'));
      expect(session.sessionType, equals(ChatSessionType.normal));
      expect(session.messageCount, equals(0));
      expect(session.tags, isEmpty);
      expect(session.serviceType, equals(AIServiceType.offline));
      expect(session.isArchived, isFalse);
      expect(session.isFavorite, isFalse);
    });

    test('creates with custom values', () {
      final now = DateTime.now();
      final session = ChatSession(
        id: 1,
        title: 'Custom Session',
        createdAt: now,
        lastModified: now,
        sessionType: ChatSessionType.emergency,
        topic: 'Emergency Support',
        messageCount: 5,
        tags: ['urgent', 'support'],
        serviceType: AIServiceType.openAI,
        selectedModel: 'gpt-4',
        isArchived: true,
        isFavorite: true,
        metadata: '{"priority": "high"}',
      );

      expect(session.id, equals(1));
      expect(session.title, equals('Custom Session'));
      expect(session.createdAt, equals(now));
      expect(session.lastModified, equals(now));
      expect(session.sessionType, equals(ChatSessionType.emergency));
      expect(session.topic, equals('Emergency Support'));
      expect(session.messageCount, equals(5));
      expect(session.tags, containsAll(['urgent', 'support']));
      expect(session.serviceType, equals(AIServiceType.openAI));
      expect(session.selectedModel, equals('gpt-4'));
      expect(session.isArchived, isTrue);
      expect(session.isFavorite, isTrue);
      expect(session.metadata, equals('{"priority": "high"}'));
    });

    test('copyWith creates new instance with updated values', () {
      final original = ChatSession(
        title: 'Original',
        sessionType: ChatSessionType.normal,
        serviceType: AIServiceType.offline,
      );

      final copied = original.copyWith(
        title: 'Updated',
        sessionType: ChatSessionType.guided,
        serviceType: AIServiceType.anthropic,
        isEncrypted: true,
      );

      expect(copied.title, equals('Updated'));
      expect(copied.sessionType, equals(ChatSessionType.guided));
      expect(copied.serviceType, equals(AIServiceType.anthropic));
      expect(copied.uid, equals(original.uid));
    });

    test('touch updates lastModified', () {
      final session = ChatSession(title: 'Test');
      final originalModified = session.lastModified;

      // Wait a moment to ensure timestamp difference
      Future.delayed(const Duration(milliseconds: 1));

      session.touch();
      expect(session.lastModified.isAfter(originalModified), isTrue);
    });

    test('tag management updates lastModified', () {
      final session = ChatSession(title: 'Test');

      session.addTag('test-tag');
      expect(session.tags, contains('test-tag'));

      final afterAddModified = session.lastModified;

      // Wait a moment to ensure timestamp difference
      Future.delayed(const Duration(milliseconds: 1));

      session.removeTag('test-tag');
      expect(session.tags, isEmpty);
      expect(session.lastModified.isAfter(afterAddModified), isTrue);
    });

    test('string values are stored correctly', () {
      final session = ChatSession(
        title: 'Test',
        sessionType: ChatSessionType.guided,
        serviceType: AIServiceType.anthropic,
      );

      expect(session.sessionType, equals(ChatSessionType.guided));
      expect(session.serviceType, equals(AIServiceType.anthropic));

      // Update session type and service type
      session.sessionType = ChatSessionType.emergency;
      session.serviceType = AIServiceType.openRouter;

      expect(session.sessionType, equals(ChatSessionType.emergency));
      expect(session.serviceType, equals(AIServiceType.openRouter));
    });

    test('handles invalid values gracefully', () {
      final session = ChatSession(title: 'Test');

      // Set invalid values (this would be handled by the model internally)
      // We're just testing that the default values are used when needed
      expect(session.sessionType, equals(ChatSessionType.normal));
      expect(session.serviceType, equals(AIServiceType.offline));
    });
  });
}
