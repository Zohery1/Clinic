part of 'appointments_screen.dart';

extension AppointmentsScreenParts on _AppointmentsScreenState {
  void _showNotificationsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(notificationsProvider);
          final notifier = ref.read(notificationsProvider.notifier);
          final theme = Theme.of(context);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: PopScope(
              onPopInvokedWithResult: (didPop, _) {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
              child: AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.notifications_active_rounded,
                              color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'التنبيهات والإشعارات',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    if (state.notifications.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          notifier.markAllAsRead();
                        },
                        child: Text(
                          'مسح الكل',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                content: SizedBox(
                  width: 400,
                  child: state.isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : state.notifications.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.notifications_off_outlined,
                                        size: 40, color: theme.hintColor),
                                    const SizedBox(height: 12),
                                    Text(
                                      'لا توجد إشعارات حالياً',
                                      style: TextStyle(
                                          color: theme.hintColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: state.notifications.length,
                              separatorBuilder: (_, __) => const Divider(height: 16),
                              itemBuilder: (context, index) {
                                final notification = state.notifications[index];
                                IconData icon = Icons.info_outline_rounded;
                                Color color = theme.colorScheme.primary;
                                
                                if (notification.title == 'حجز جديد') {
                                  icon = Icons.calendar_today_rounded;
                                  color = AppTheme.success;
                                } else if (notification.title == 'إضافة خدمة طبية') {
                                  icon = Icons.medical_services_outlined;
                                  color = AppTheme.completed;
                                }

                                return InkWell(
                                  onTap: () {
                                    notifier.markAsRead(notification.id);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(icon, color: color, size: 18),
                                            ),
                                            if (!notification.isRead)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.error,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                notification.title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: theme.textTheme.bodyLarge?.color,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                notification.body,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.textTheme.bodyMedium?.color,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatTimeAgo(notification.createdAt),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: theme.hintColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      ref.read(notificationsProvider.notifier).markAllAsRead();
    });
  }

  void _showCancelAllDialog(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    String clinicId,
    List<AppointmentModel> appointments,
  ) {
    final waitingCount = appointments.where((a) => a.status == 'confirmed').length;

    ClinicDialog.confirm(
      context: context,
      icon: Icons.warning_amber_rounded,
      title: 'إلغاء مواعيد اليوم',
      description: 'سيتم إلغاء كل مواعيد الانتظار ($waitingCount موعد) لهذا اليوم. لا يشمل ذلك المواعيد المكتملة أو قيد الفحص.',
      confirmLabel: 'إلغاء المواعيد',
      isDangerous: true,
      onConfirm: () async {
        await ref.read(appointmentRepositoryProvider).cancelAllTodayAppointments(
              clinicId,
              selectedDate,
            );
        ref.invalidate(todayAppointmentsProvider);

        try {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
            title: 'إلغاء جميع المواعيد',
            body: 'قام الطبيب بإلغاء جميع مواعيد الانتظار لهذا اليوم ($waitingCount موعد)',
            targetRole: 'secretary',
            playSound: true,
          );
        } catch (_) {}

        if (context.mounted) {
          ClinicToast.showSuccess(context, 'تم إلغاء مواعيد الانتظار بنجاح');
        }
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
    DateTime selectedDate,
  ) {
    final todayFormatted =
        intl.DateFormat('d MMMM، yyyy', 'ar').format(selectedDate);
    final dayName = intl.DateFormat('EEEE', 'ar').format(selectedDate);

    return Column(
      children: [
        // ─── Horizontal Calendar Strip ───
        _buildCalendarStrip(context, ref, selectedDate, dayName, todayFormatted, user),
        const SizedBox(height: 16),
        // ─── Queue Board ───
        Expanded(
          child: appointmentsAsync.when(
            data: (appointments) => QueueBoard(appointments: appointments, clinicId: user.clinicId),
            loading: () => ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: 4,
              itemBuilder: (_, __) => _buildSkeletonCard(context),
            ),
            error: (err, _) => Center(
              child: Text('حدث خطأ في تحميل البيانات',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarStrip(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    String dayName,
    String formattedDate,
    dynamic user,
  ) {
    // Generate 7 days: Sat through Fri
    final now = DateTime.now();
    // Find the Saturday of this week
    final diff = now.weekday >= DateTime.saturday ? now.weekday - DateTime.saturday : now.weekday + 7 - DateTime.saturday;
    final saturday = now.subtract(Duration(days: diff));
    final days = List.generate(7, (i) => saturday.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          // Calendar icon button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2024, 1, 1),
                  lastDate: DateTime(2028, 12, 31),
                );
                if (picked != null) {
                  ref.read(selectedDateProvider.notifier).state =
                      DateTime(picked.year, picked.month, picked.day);
                }
              },
              icon: Icon(Icons.calendar_month_rounded,
                  color: Theme.of(context).colorScheme.primary, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: days.map((day) {
                final isSelected = DateUtils.isSameDay(selectedDate, day);
                final dayLabel = intl.DateFormat('E', 'ar').format(day);
                final dayNum = intl.DateFormat('d').format(day);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedDateProvider.notifier).state =
                          DateTime(day.year, day.month, day.day);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getShortDayName(dayLabel),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayNum,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(width: 8),
          _buildDoctorFilterChip(context, ref, user),
          const SizedBox(width: 8),
          _buildBranchFilterChip(context, ref, user),

          if (MediaQuery.of(context).size.width >= 1150) ...[
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'مواعيد $dayName',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoctorFilterChip(BuildContext context, WidgetRef ref, dynamic user) {
    if (user == null) return const SizedBox.shrink();
    final doctorsAsync = ref.watch(clinicDoctorsProvider(user.clinicId));
    final selectedDoctorId = ref.watch(selectedDoctorFilterProvider);

    return doctorsAsync.when(
      data: (doctors) {
        if (doctors.length <= 1) return const SizedBox.shrink();
        final canSeeAll = user.isOwner || user.canViewReports || user.role == UserRole.secretary;
        if (!canSeeAll) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedDoctorId,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Theme.of(context).hintColor),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'Cairo',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('جميع الأطباء'),
                ),
                ...doctors.map(
                  (doc) => DropdownMenuItem<String?>(
                    value: doc.id,
                    child: Text('د. ${doc.fullName}'),
                  ),
                ),
              ],
              onChanged: (val) {
                ref.read(selectedDoctorFilterProvider.notifier).state = val;
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBranchFilterChip(BuildContext context, WidgetRef ref, dynamic user) {
    if (user == null) return const SizedBox.shrink();
    final branchesAsync = ref.watch(clinicBranchesProvider(user.clinicId));
    final selectedBranchId = ref.watch(selectedBranchFilterProvider);

    return branchesAsync.when(
      data: (branches) {
        if (branches.length <= 1) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedBranchId,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Theme.of(context).hintColor),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'Cairo',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('جميع الفروع'),
                ),
                ...branches.map(
                  (br) => DropdownMenuItem<String?>(
                    value: br.id,
                    child: Text(br.name),
                  ),
                ),
              ],
              onChanged: (val) {
                ref.read(selectedBranchFilterProvider.notifier).state = val;
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String? clinicId}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 48,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد مواعيد مجدولة لليوم',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اضغط على "حجز جديد" لإضافة موعد',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final user = ref.read(currentUserProvider);
              showDialog(
                context: context,
                builder: (_) => BookAppointmentDialog(clinicId: user?.clinicId ?? clinicId ?? ''),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('حجز جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 16,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileRevenueSummary(BuildContext context, WidgetRef ref, AsyncValue<List<AppointmentModel>> appointmentsAsync) {
    final todayRevenueAsync = ref.watch(todayRevenueProvider);
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: AppTheme.cardDecoration(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إيرادات اليوم',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      todayRevenueAsync.when(
                        data: (revenue) => Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              revenue.toStringAsFixed(0),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'ج.م',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        loading: () => Container(width: 60, height: 20, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4))),
                        error: (_, __) => const Text('--', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.trending_up_rounded, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981), size: 18),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: AppTheme.cardDecoration(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مواعيد اليوم',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      appointmentsAsync.when(
                        data: (list) => Text(
                          '${list.length}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        loading: () => Container(width: 40, height: 20, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4))),
                        error: (_, __) => const Text('--', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
    DateTime selectedDate,
    int unreadCount,
  ) {
    final actualTodayFormatted =
        intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => BookAppointmentDialog(clinicId: user?.clinicId ?? ''),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text('حجز جديد', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ),
        body: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            ref.invalidate(todayAppointmentsProvider);
            ref.invalidate(todayRevenueProvider);
            ref.invalidate(monthRevenueProvider);
            ref.invalidate(weeklyRevenueProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.local_hospital_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateTime.now().hour < 12 ? 'صباح الخير' : 'مساء الخير'}، ${user.fullName.split(' ').first}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                actualTodayFormatted,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const ClinicSwitcherButton(),
                        const SizedBox(width: 8),
                        // Orange Receipt / Invoice Top-Up Button (فاتورة الاشتراك)
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => SubscriptionStatusSheet(
                                  subscriptionEndDate: widget.subscriptionEndDate,
                                  clinicName: widget.clinicName ?? 'العيادة',
                                  clinicId: widget.clinicId ?? user.clinicId,
                                  inviteCode: widget.inviteCode ?? '',
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFFEA580C),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bell notification button for mobile
                        Stack(
                          children: [
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () => _showNotificationsDialog(context, ref),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ─── إحصائيات سريعة (الايراد اليومي والمواعيد) ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildMobileRevenueSummary(context, ref, appointmentsAsync),
                ),
              ),
              // ─── شريط اختيار التاريخ (موبايل) ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              final day = DateTime.now()
                                  .subtract(const Duration(days: 3))
                                  .add(Duration(days: index));
                              final isSelected =
                                  DateUtils.isSameDay(selectedDate, day);
                              final dayName =
                                  intl.DateFormat('E', 'ar').format(day);
                              final dayNumber = intl.DateFormat('d').format(day);

                              return GestureDetector(
                                onTap: () {
                                  ref
                                      .read(selectedDateProvider.notifier)
                                      .state = DateTime(
                                      day.year, day.month, day.day);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 56,
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primary.withValues(alpha: 0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            )
                                          ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          dayName,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dayNumber,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context).textTheme.bodyLarge?.color,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        height: 58,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.calendar_month_rounded,
                              color: Theme.of(context).colorScheme.primary, size: 20),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2024, 1, 1),
                              lastDate: DateTime(2028, 12, 31),
                            );
                            if (picked != null) {
                              ref.read(selectedDateProvider.notifier).state =
                                  DateTime(
                                      picked.year, picked.month, picked.day);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ─── فلاتر الأطباء والفروع (موبايل) ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      _buildDoctorFilterChip(context, ref, user),
                      const SizedBox(width: 8),
                      _buildBranchFilterChip(context, ref, user),
                    ],
                  ),
                ),
              ),
              // ─── عنوان القائمة ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'مواعيد اليوم',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const Spacer(),
                      appointmentsAsync.when(
                        data: (appointments) {
                          final waitingCount = appointments.where((a) => a.status == 'confirmed').length;
                          if (waitingCount == 0) return const SizedBox.shrink();
                          return TextButton(
                            onPressed: () => _showCancelAllDialog(context, ref, selectedDate, user.clinicId, appointments),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('إلغاء الكل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                BookAppointmentDialog(clinicId: user.clinicId),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('حجز جديد',
                            style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
              // ─── تبويبات التصفية (الانتظار، مع الطبيب، مكتمل، ملغي) ───
              appointmentsAsync.when(
                data: (appointments) => _buildMobileFilterTabs(
                  context,
                  appointments,
                  _selectedMobileTab,
                  (index) => setSelectedMobileTab(index),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              // ─── قائمة المواعيد ───
              _buildMobileAppointmentsList(
                  context, appointmentsAsync, ref, user.clinicId, _selectedMobileTab),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        // duplicate floatingActionButton removed
      ),
    );
  }

  Widget _buildMobileFilterTabs(
    BuildContext context,
    List<AppointmentModel> appointments,
    int selectedTab,
    void Function(int) onTabSelected,
  ) {
    final waitingCount = appointments.where((a) => a.status == 'confirmed').length;
    final withDoctorCount = appointments.where((a) => a.status == 'pending').length;
    final completedCount = appointments.where((a) => a.status == 'completed').length;
    final cancelledCount = appointments.where((a) => a.status.startsWith('cancelled')).length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [

              _buildFilterChip(context, 0, 'الانتظار', waitingCount, const Color(0xFFF59E0B), selectedTab, onTabSelected),
              const SizedBox(width: 8),
              _buildFilterChip(context, 1, 'مع الطبيب', withDoctorCount, const Color(0xFF3B82F6), selectedTab, onTabSelected),
              const SizedBox(width: 8),
              _buildFilterChip(context, 2, 'مكتمل', completedCount, const Color(0xFF10B981), selectedTab, onTabSelected),
              const SizedBox(width: 8),
              _buildFilterChip(context, 3, 'ملغي', cancelledCount, const Color(0xFFEF4444), selectedTab, onTabSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    int index,
    String label,
    int count,
    Color color,
    int selectedTab,
    void Function(int) onTabSelected,
  ) {
    final isSelected = selectedTab == index;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: isSelected ? 1.0 : 0.5), width: 1.5),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAppointmentsList(
    BuildContext context,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
    WidgetRef ref,
    String clinicId,
    int selectedTab,
  ) {
    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState(context));
        }

        // تقسيم المواعيد لأربع قوائم حسب الحالة
        final waiting = appointments
            .where((a) => a.status == 'confirmed')
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

        final withDoctor = appointments
            .where((a) => a.status == 'pending')
            .toList();

        final completed = appointments
            .where((a) => a.status == 'completed')
            .toList()
          ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

        final cancelled = appointments
            .where((a) => a.status.startsWith('cancelled'))
            .toList()
          ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

        List<AppointmentModel> currentList;
        QueueLaneType laneType;
        switch (selectedTab) {
          case 0:
            currentList = waiting;
            laneType = QueueLaneType.waiting;
            break;
          case 1:
            currentList = withDoctor;
            laneType = QueueLaneType.withDoctor;
            break;
          case 2:
            currentList = completed;
            laneType = QueueLaneType.completed;
            break;
          case 3:
            currentList = cancelled;
            laneType = QueueLaneType.cancelled;
            break;
          default:
            currentList = waiting;
            laneType = QueueLaneType.waiting;
        }

        if (currentList.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 48, color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد مواعيد في هذا القسم',
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final appt = currentList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QueueCard(
                    appointment: appt,
                    laneType: laneType,
                    queuePosition: laneType == QueueLaneType.waiting ? index + 1 : null,
                    clinicId: clinicId,
                    withDoctorCount: withDoctor.length,
                  ),
                );
              },
              childCount: currentList.length,
            ),
          ),
        );
      },
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => _buildSkeletonCard(context),
            childCount: 4,
          ),
        ),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('حدث خطأ في تحميل البيانات',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ),
      ),
    );
  }
}
