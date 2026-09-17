import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/notifications/domain/entities/notification_entity.dart';

void main() {
  group('notificationActionFromString', () {
    test('mapeia actions conhecidas', () {
      expect(
        notificationActionFromString('professional'),
        NotificationAction.professional,
      );
      expect(
        notificationActionFromString('professionals'),
        NotificationAction.professionals,
      );
      expect(notificationActionFromString('plans'), NotificationAction.plans);
      expect(
        notificationActionFromString('partners'),
        NotificationAction.partners,
      );
    });

    test('payload FCM inválido vira none', () {
      expect(notificationActionFromString(null), NotificationAction.none);
      expect(notificationActionFromString(''), NotificationAction.none);
      expect(notificationActionFromString('foo'), NotificationAction.none);
    });
  });
}
