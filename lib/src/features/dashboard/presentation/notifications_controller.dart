import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/notification_model.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? errorMessage;

  NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref _ref;
  RealtimeChannel? _subscription;

  NotificationsNotifier(this._ref) : super(NotificationsState()) {
    _init();
  }

  void _init() {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    
    fetchNotifications();
    _subscribeToRealtime(user.clinicId);
  }

  Future<void> fetchNotifications() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final roleName = user.role == UserRole.doctor ? 'doctor' : 'secretary';

      // 1. Purge/delete read notifications from the database to prevent DB bloat
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('clinic_id', user.clinicId)
          .eq('is_read', true);

      // 2. Fetch unread notifications for this clinic
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('clinic_id', user.clinicId)
          .order('created_at', ascending: false)
          .limit(50);
          
      final list = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .where((n) => n.targetRole == null || n.targetRole == roleName)
          .toList();
          
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _subscribeToRealtime(String clinicId) {
    _subscription?.unsubscribe();
    
    _subscription = Supabase.instance.client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'clinic_id',
            value: clinicId,
          ),
          callback: (payload) {
            final newNotification = NotificationModel.fromJson(payload.newRecord);
            final user = _ref.read(currentUserProvider);
            final roleName = user?.role == UserRole.doctor ? 'doctor' : 'secretary';

            // Only notify if notification is intended for this role or all roles
            if (newNotification.targetRole == null || newNotification.targetRole == roleName) {
              state = state.copyWith(
                notifications: [newNotification, ...state.notifications],
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // Physically delete from DB when seen to keep database clean
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);
          
      state = state.copyWith(
        notifications: state.notifications.where((n) => n.id != notificationId).toList(),
      );
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      // Delete all notifications for this role to keep DB lean
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('clinic_id', user.clinicId);
          
      state = state.copyWith(
        notifications: [],
      );
    } catch (e) {
      // Fail silently
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
