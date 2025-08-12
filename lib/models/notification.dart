import 'package:hive_flutter/adapters.dart';

part 'notification.g.dart';

@HiveType(typeId: 0)
class NotificationModel extends HiveObject {
  @HiveField(0, defaultValue: 0)
  final String? title;
  @HiveField(1)
  final String? body;
  @HiveField(2)
  final String route;
  @HiveField(3)
  final String type;

  NotificationModel({
    required this.title,
    required this.body,
    required this.route,
    required this.type,
  });
}
