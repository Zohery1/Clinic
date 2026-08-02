import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:uuid/uuid.dart';
import '../domain/notification_model.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;

  NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref _ref;
  RealtimeChannel? _subscription;
  final _uuid = const Uuid();

  NotificationsNotifier(this._ref) : super(NotificationsState()) {
    _init();
  }

  void _init() {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    
    // 1. Wipe all old notifications from the database (As requested by the user to start clean)
    try {
      Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('clinic_id', user.clinicId);
    } catch (_) {}

    // 2. Subscribe to Ephemeral Broadcasts (No DB persistence)
    _subscribeToBroadcasts(user);
  }

  void _subscribeToBroadcasts(UserModel user) {
    _subscription?.unsubscribe();
    
    final roleName = user.role == UserRole.doctor ? 'doctor' : 'secretary';

    _subscription = Supabase.instance.client
        .channel('clinic_notifications_${user.clinicId}')
        .onBroadcast(
          event: 'notification',
          callback: (payload) {
            // Rule 1: Do not show notification to the person who triggered it
            final senderId = payload['sender_id'] as String?;
            if (senderId == user.id) return;

            final targetRole = payload['target_role'] as String?;
            // Only notify if notification is intended for this role or all roles
            if (targetRole == null || targetRole == roleName) {
              
              // Create local ephemeral notification object
              final newNotification = NotificationModel(
                id: _uuid.v4(),
                clinicId: user.clinicId,
                title: payload['title'] ?? '',
                body: payload['body'] ?? '',
                isRead: false,
                targetRole: targetRole,
                createdAt: DateTime.now(),
              );

              // Rule 2: Play sound if requested
              final bool playSound = payload['play_sound'] == true;
              if (playSound) {
                FlutterRingtonePlayer().playNotification();
              }

              state = state.copyWith(
                notifications: [newNotification, ...state.notifications],
              );
            }
          },
        )
        .subscribe();
  }

  void sendBroadcastNotification({
    required String title,
    required String body,
    String? targetRole,
    bool playSound = false,
  }) {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    Supabase.instance.client
        .channel('clinic_notifications_${user.clinicId}')
        .sendBroadcastMessage(
      event: 'notification',
      payload: {
        'sender_id': user.id,
        'title': title,
        'body': body,
        'target_role': targetRole,
        'play_sound': playSound,
      },
    );
  }

  void markAsRead(String notificationId) {
    // Simply remove from local memory
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != notificationId).toList(),
    );
  }

  void markAllAsRead() {
    // Simply clear the local memory array
    state = state.copyWith(
      notifications: [],
    );
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});
