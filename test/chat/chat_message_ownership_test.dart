import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/chat/model/chat_message.dart';
import 'package:bagyesrushappusernew/src/chat/model/conversation.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/message_grouping.dart';

ChatMessage _message({required String senderId, required bool isMine}) =>
    ChatMessage.fromJson({
      'id': 1,
      'conversation_id': 62,
      'type': 'text',
      'body': 'I am at the gate',
      'sender': {'id': senderId, 'name': 'Kofi A.'},
      'is_mine': isMine,
      'created_at': '2026-09-29T18:31:00Z',
    });

void main() {
  group('ChatMessage.resolvedFor', () {
    test("a peer's broadcast flagged is_mine by the sender is not ours", () {
      final resolved = _message(senderId: '31', isMine: true).resolvedFor('14');
      expect(resolved.isMine, isFalse);
    });

    test('our own echoed message is ours even if flagged otherwise', () {
      final resolved = _message(senderId: '14', isMine: false).resolvedFor('14');
      expect(resolved.isMine, isTrue);
    });

    test('keeps the payload flag when our id is unknown', () {
      expect(_message(senderId: '31', isMine: true).resolvedFor(null).isMine,
          isTrue);
    });

    test('keeps optimistic bubbles (no sender id) as ours', () {
      final optimistic = ChatMessage.optimistic(
        conversationId: '62',
        body: 'On my way down',
        clientUuid: 'abc',
        senderName: 'You',
      );
      expect(optimistic.resolvedFor('14').isMine, isTrue);
    });
  });

  test('Conversation.me is the is_me participant', () {
    final conversation = Conversation.fromJson({
      'id': 62,
      'participants': [
        {'user_id': 31, 'role': 'rider', 'name': 'Kofi A.', 'is_me': false},
        {'user_id': 14, 'role': 'customer', 'name': 'Ama M.', 'is_me': true},
      ],
    });
    expect(conversation.me?.userId, '14');
    expect(conversation.counterpart?.userId, '31');
  });

  group('isSameMessageGroup', () {
    ChatMessage at(String senderId, String time, {bool isMine = false}) =>
        ChatMessage.fromJson({
          'id': time,
          'conversation_id': 62,
          'body': 'hi',
          'sender': {'id': senderId, 'name': 'x'},
          'is_mine': isMine,
          'created_at': time,
        });

    test('same sender a minute apart groups', () {
      expect(
        isSameMessageGroup(
          at('31', '2026-09-29T18:31:00Z'),
          at('31', '2026-09-29T18:32:00Z'),
        ),
        isTrue,
      );
    });

    test('a different sender breaks the group', () {
      expect(
        isSameMessageGroup(
          at('31', '2026-09-29T18:31:00Z'),
          at('14', '2026-09-29T18:31:30Z', isMine: true),
        ),
        isFalse,
      );
    });

    test('a long pause breaks the group', () {
      expect(
        isSameMessageGroup(
          at('31', '2026-09-29T18:00:00Z'),
          at('31', '2026-09-29T18:20:00Z'),
        ),
        isFalse,
      );
    });
  });

  test('chatDayLabel names today, yesterday, then the date', () {
    final now = DateTime(2026, 9, 29, 18);
    expect(chatDayLabel(DateTime(2026, 9, 29, 9), now: now), 'Today');
    expect(chatDayLabel(DateTime(2026, 9, 28, 9), now: now), 'Yesterday');
    expect(chatDayLabel(DateTime(2026, 9, 21, 9), now: now), 'Mon, 21 Sep');
    expect(chatDayLabel(DateTime(2025, 9, 21, 9), now: now), 'Sun, 21 Sep 2025');
  });
}
