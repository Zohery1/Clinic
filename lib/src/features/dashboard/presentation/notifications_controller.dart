import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/notification_model.dart';
import '../../auth/presentation/login_controller.dart';

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
    state = state.copyWith(isLoading: true);
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
          
      final list = (response as List)
          .map((json) => NotificationModel.fromJson(json))
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
            // Prepend new notification to the list
            state = state.copyWith(
              notifications: [newNotification, ...state.notifications],
            );
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
          
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList(),
      );
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;
      
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('clinic_id', user.clinicId)
          .eq('is_read', false);
          
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
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
