/// Canonical Arabic labels for appointment status strings as stored in the
/// database. Every widget that renders a status to the user must go through
/// this map — raw enum values like `cancelled_by_clinic` leaking into the UI
/// is a defect class this file exists to prevent.
///
/// The cancel variants are rendered wherever lists surface past appointments
/// (dashboard today-queue, appointment cards, details cards) and were the main
/// reason this map was centralized.
const Map<String, String> appointmentStatusLabels = <String, String>{
  'pending': 'بالانتظار',
  'confirm': 'بالانتظار', // legacy spelling that exists in old rows
  'waiting': 'بالانتظار',
  'confirmed': 'في الانتظار',
  'in_progress': 'بالكشف',
  'completed': 'مكتمل',
  'cancelled': 'ملغي',
  'cancelled_by_patient': 'معتذر',
  'cancelled_by_clinic': 'ملغي من العيادة',
};

/// True when the row represents a cancellation (any party).
bool isCancelledStatus(String status) => status == 'cancelled' || status.startsWith('cancelled');

/// Label for a status; unknown values fall back to a neutral Arabic label
/// rather than a raw database enum.
String appointmentStatusLabel(String status) =>
    appointmentStatusLabels[status] ?? 'غير محدد';
