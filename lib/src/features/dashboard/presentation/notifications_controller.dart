import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/web_audio_helper.dart';
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
            final Map<String, dynamic> data = (payload['payload'] is Map<String, dynamic>)
                ? payload['payload'] as Map<String, dynamic>
                : payload;

            // Rule 1: Do not show notification to the person who triggered it
            final senderId = data['sender_id'] as String?;
            if (senderId != null && senderId == user.id) return;

            final targetRole = data['target_role'] as String?;
            // Only notify if notification is intended for this role or all roles
            if (targetRole == null || targetRole == roleName) {
              final title = data['title'] as String? ?? '';
              final body = data['body'] as String? ?? '';

              if (title.trim().isEmpty && body.trim().isEmpty) return;

              // Create local ephemeral notification object
              final newNotification = NotificationModel(
                id: _uuid.v4(),
                clinicId: user.clinicId,
                title: title,
                body: body,
                isRead: false,
                targetRole: targetRole,
                createdAt: DateTime.now(),
              );

              // Rule 2: Play sound if requested
              final bool playSound = data['play_sound'] == true;
              if (playSound) {
                _playNotificationSound();
              }

              state = state.copyWith(
                notifications: [newNotification, ...state.notifications],
              );
            }
          },
        )
        .subscribe();
  }

  static void _playNotificationSound() {
    if (kIsWeb) {
      try {
        playWebNotificationChime();
      } catch (_) {}
    }
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    try {
      FlutterRingtonePlayer().playNotification(
        volume: 1.0,
        asAlarm: false,
      );
    } catch (_) {}
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
    // 1. Remove from local memory state
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != notificationId).toList(),
    );

    // 2. Delete from Supabase DB
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      try {
        Supabase.instance.client
            .from('notifications')
            .delete()
            .eq('id', notificationId);
      } catch (_) {}
    }
  }

  void markAllAsRead() {
    // 1. Clear local memory array
    state = state.copyWith(
      notifications: [],
    );

    // 2. Wipe database notifications table for this clinic
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      try {
        Supabase.instance.client
            .from('notifications')
            .delete()
            .eq('clinic_id', user.clinicId);
      } catch (_) {}
    }
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
