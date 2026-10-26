import '../../features/auth/domain/user_model.dart';
import '../../features/appointments/domain/appointment_model.dart';
import '../../features/appointments/domain/appointment_service_model.dart';
import '../../features/patients/domain/patient_model.dart';
import '../../features/reports/domain/financial_report_model.dart';

/// بيانات سريرية واقعية كاملة للعرض التجريبي والمعاينة اللحظية
/// تُمكن الأطباء وأطقم التمريض والمراجعين من استعراض كافة وظائف النظام
/// بأعلى كثافة معلوماتية وتصميم طبي احترافي
class DemoClinicalData {
  DemoClinicalData._();

  static final DateTime today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // مستخدم الطبيب مالك العيادة
  static final UserModel doctorUser = UserModel(
    id: 'doc-01',
    clinicId: 'demo-clinic-01',
    activeClinicId: 'demo-clinic-01',
    activeBranchId: 'branch-01',
    role: UserRole.doctor,
    fullName: 'د. عبد الرحمن الزهيري',
    phone: '01012345678',
    isActive: true,
    isOwner: true,
    canDeleteAppointments: true,
    canViewReports: true,
    canEditServices: true,
    canViewMedicalHistory: true,
    canEditMedicalNotes: true,
    canCancelAppointments: true,
    createdAt: DateTime(2025, 1, 1),
  );

  // قائمة المرضى الشاملة
  static final List<PatientModel> patients = [
    PatientModel(
      id: 'pat-01',
      clinicId: 'demo-clinic-01',
      fullName: 'أحمد محمود عبد العزيز',
      phone: '01098765432',
      gender: 'male',
      birthDate: DateTime(1982, 5, 14),
      address: 'المعادي، القاهرة - شارع 9',
      medicalHistory: 'خشونة بالركبة اليمنى من الدرجة الثانية | حساسية من البنسلين | ضغط دم منتظم بالعلاج',
      branchId: 'branch-01',
      createdAt: DateTime(2024, 2, 10),
    ),
    PatientModel(
      id: 'pat-02',
      clinicId: 'demo-clinic-01',
      fullName: 'سارة كمال الشناوي',
      phone: '01123456789',
      gender: 'female',
      birthDate: DateTime(1995, 11, 20),
      address: 'التجمع الخامس، القاهرة الجديدة',
      medicalHistory: 'متابعة دورية بعد جراحة بالكتف الأيسر | لا توجد حساسيات دوائية معروفة',
      branchId: 'branch-01',
      createdAt: DateTime(2024, 3, 15),
    ),
    PatientModel(
      id: 'pat-03',
      clinicId: 'demo-clinic-01',
      fullName: 'محمود حسن خليل',
      phone: '01234567890',
      gender: 'male',
      birthDate: DateTime(1966, 8, 3),
      address: 'مدينة نصر، القاهرة',
      medicalHistory: 'داء السكري من النوع الثاني منذ 10 سنوات | اعتلال أعصاب طرفية طفيف',
      branchId: 'branch-01',
      createdAt: DateTime(2024, 1, 5),
    ),
    PatientModel(
      id: 'pat-04',
      clinicId: 'demo-clinic-01',
      fullName: 'نادية عبد الله إبراهيم',
      phone: '01055566677',
      gender: 'female',
      birthDate: DateTime(1988, 3, 27),
      address: 'المهندسين، الجيزة',
      medicalHistory: 'التهاب أوتار الكاحل المتكرر | حساسية مركبات السلفا',
      branchId: 'branch-01',
      createdAt: DateTime(2024, 4, 1),
    ),
    PatientModel(
      id: 'pat-05',
      clinicId: 'demo-clinic-01',
      fullName: 'كريم يوسف منصور',
      phone: '01511223344',
      gender: 'male',
      birthDate: DateTime(1993, 9, 12),
      address: 'مصر الجديدة، القاهرة',
      medicalHistory: 'إصابة ملاعب - تمزق جزئي في الرباط الصليبي الأمامي',
      branchId: 'branch-01',
      createdAt: DateTime(2024, 5, 8),
    ),
    PatientModel(
      id: 'pat-06',
      clinicId: 'demo-clinic-01',
      fullName: 'مريم خالد إبراهيم',
      phone: '01099887766',
      gender: 'female',
      birthDate: DateTime(2000, 7, 18),
      address: 'الشيخ زايد، الجيزة',
      medicalHistory: 'انحناء طفيف بالعمود الفقري (جنف وظيفي) | تخضع للعلاج الطبيعي',
      branchId: 'branch-01',
      createdAt: DateTime(2024, 6, 2),
    ),
  ];

  // مواعيد اليوم الواقعية عبر كافة مراحل الطابور السريري
  static final List<AppointmentModel> appointments = [
    // 1. قيد الكشف الآن في غرفة الطبيب
    AppointmentModel(
      id: 'appt-01',
      clinicId: 'demo-clinic-01',
      branchId: 'branch-01',
      branchName: 'فرع المعادي الرئيسي',
      patientId: 'pat-01',
      doctorId: 'doc-01',
      doctorName: 'د. عبد الرحمن الزهيري',
      appointmentTypeId: 'type-01',
      appointmentTypeName: 'كشف جديد تخصصي',
      appointmentDate: today.add(const Duration(hours: 10, minutes: 30)),
      status: 'pending', // قيد الكشف
      priceCharged: 350.0,
      totalPaid: 500.0,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      serviceNames: ['كشف عظام دقيق', 'فحص سونار حركي للمفصل'],
      patient: AppointmentPatient(
        fullName: 'أحمد محمود عبد العزيز',
        phone: '01098765432',
        address: 'المعادي، القاهرة - شارع 9',
      ),
    ),

    // 2. تذكرة رقم #102 في صالة الانتظار (التالي مباشرة)
    AppointmentModel(
      id: 'appt-02',
      clinicId: 'demo-clinic-01',
      branchId: 'branch-01',
      branchName: 'فرع المعادي الرئيسي',
      patientId: 'pat-02',
      doctorId: 'doc-01',
      doctorName: 'د. عبد الرحمن الزهيري',
      appointmentTypeId: 'type-02',
      appointmentTypeName: 'استشارة ومتابعة أشعة',
      appointmentDate: today.add(const Duration(hours: 11, minutes: 00)),
      status: 'confirmed', // في الانتظار
      priceCharged: 200.0,
      totalPaid: 200.0,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      serviceNames: ['استشارة عظام'],
      patient: AppointmentPatient(
        fullName: 'سارة كمال الشناوي',
        phone: '01123456789',
        address: 'التجمع الخامس، القاهرة الجديدة',
      ),
    ),

    // 3. تذكرة رقم #103 في صالة الانتظار
    AppointmentModel(
      id: 'appt-03',
      clinicId: 'demo-clinic-01',
      branchId: 'branch-01',
      branchName: 'فرع المعادي الرئيسي',
      patientId: 'pat-03',
      doctorId: 'doc-01',
      doctorName: 'د. عبد الرحمن الزهيري',
      appointmentTypeId: 'type-01',
      appointmentTypeName: 'كشف عظام وأعصاب طرفية',
      appointmentDate: today.add(const Duration(hours: 11, minutes: 30)),
      status: 'confirmed',
      priceCharged: 350.0,
      totalPaid: 350.0,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      serviceNames: ['كشف عظام دقيق'],
      patient: AppointmentPatient(
        fullName: 'محمود حسن خليل',
        phone: '01234567890',
        address: 'مدينة نصر، القاهرة',
      ),
    ),

    // 4. تذكرة رقم #104 في صالة الانتظار
    AppointmentModel(
      id: 'appt-04',
      clinicId: 'demo-clinic-01',
      branchId: 'branch-01',
      branchName: 'فرع المعادي الرئيسي',
      patientId: 'pat-04',
      doctorId: 'doc-01',
      doctorName: 'د. عبد الرحمن الزهيري',
      appointmentTypeId: 'type-03',
      appointmentTypeName: 'جلسة حقن موضعي بلازما',
      appointmentDate: today.add(const Duration(hours: 12, minutes: 00)),
      status: 'confirmed',
      priceCharged: 700.0,
      totalPaid: 700.0,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 50)),
      serviceNames: ['حقن موضعي مفصل الكاحل'],
      patient: AppointmentPatient(
        fullName: 'نادية عبد الله إبراهيم',
        phone: '01055566677',
        address: 'المهندسين، الجيزة',
      ),
    ),

    // 5. موعد مكتمل اليوم
    AppointmentModel(
      id: 'appt-05',
      clinicId: 'demo-clinic-01',
      branchId: 'branch-01',
      branchName: 'فرع المعادي الرئيسي',
      patientId: 'pat-05',
      doctorId: 'doc-01',
      doctorName: 'د. عبد الرحمن الزهيري',
      appointmentTypeId: 'type-01',
      appointmentTypeName: 'كشف إصابات ملاعب',
      appointmentDate: today.add(const Duration(hours: 9, minutes: 30)),
      status: 'completed',
      priceCharged: 350.0,
      totalPaid: 450.0,
      updatedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      serviceNames: ['كشف إصابات ملاعب', 'تثبيت دعامة الركبة'],
      patient: AppointmentPatient(
        fullName: 'كريم يوسف منصور',
        phone: '01511223344',
        address: 'مصر الجديدة، القاهرة',
      ),
    ),

    // 6. موعد مكتمل اليوم
    AppointmentModel(
      id: 'appt-06',
      clinicId: 'demo-clinic-01',
      branchId: 'branch-01',
      branchName: 'فرع المعادي الرئيسي',
      patientId: 'pat-06',
      doctorId: 'doc-01',
      doctorName: 'د. عبد الرحمن الزهيري',
      appointmentTypeId: 'type-02',
      appointmentTypeName: 'متابعة تقويم عمود فقري',
      appointmentDate: today.add(const Duration(hours: 10, minutes: 00)),
      status: 'completed',
      priceCharged: 200.0,
      totalPaid: 350.0,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 55)),
      serviceNames: ['استشارة متابعة', 'تخطيط برنامج العلاج الطبيعي'],
      patient: AppointmentPatient(
        fullName: 'مريم خالد إبراهيم',
        phone: '01099887766',
        address: 'الشيخ زايد، الجيزة',
      ),
    ),

    // 7. موعد تم إلغاؤه واعتذار المريض
    AppointmentModel(
      id: 'appt-07',
      clinicId: 'demo-clinic-01',
      branchId: 'branch-01',
      branchName: 'فرع المعادي الرئيسي',
      patientId: 'pat-04',
      doctorId: 'doc-01',
      doctorName: 'د. عبد الرحمن الزهيري',
      appointmentTypeId: 'type-01',
      appointmentTypeName: 'كشف عظام',
      appointmentDate: today.add(const Duration(hours: 13, minutes: 00)),
      status: 'cancelled',
      priceCharged: 0.0,
      totalPaid: 0.0,
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      serviceNames: [],
      patient: AppointmentPatient(
        fullName: 'هند علي سليم',
        phone: '01299443322',
        address: 'الدقي، الجيزة',
      ),
    ),
  ];

  // خدمات الموعد الأول
  static final List<AppointmentServiceModel> demoServices = [
    AppointmentServiceModel(
      id: 'srv-01',
      clinicId: 'demo-clinic-01',
      appointmentId: 'appt-01',
      serviceId: 's-01',
      serviceName: 'كشف عظام استشاري دقيق',
      priceCharged: 350.0,
    ),
    AppointmentServiceModel(
      id: 'srv-02',
      clinicId: 'demo-clinic-01',
      appointmentId: 'appt-01',
      serviceId: 's-02',
      serviceName: 'فحص سونار حركي للمفصل',
      priceCharged: 150.0,
    ),
  ];

  // التقرير المالي اليومي والشهري
  static final List<FinancialReportModel> financialReport = [
    FinancialReportModel(
      clinicId: 'demo-clinic-01',
      reportDate: today,
      reportMonth: DateTime(today.year, today.month, 1),
      totalRevenue: 4850.0,
    ),
    FinancialReportModel(
      clinicId: 'demo-clinic-01',
      reportDate: today.subtract(const Duration(days: 1)),
      reportMonth: DateTime(today.year, today.month, 1),
      totalRevenue: 4200.0,
    ),
    FinancialReportModel(
      clinicId: 'demo-clinic-01',
      reportDate: today.subtract(const Duration(days: 2)),
      reportMonth: DateTime(today.year, today.month, 1),
      totalRevenue: 5100.0,
    ),
    FinancialReportModel(
      clinicId: 'demo-clinic-01',
      reportDate: today.subtract(const Duration(days: 3)),
      reportMonth: DateTime(today.year, today.month, 1),
      totalRevenue: 3800.0,
    ),
    FinancialReportModel(
      clinicId: 'demo-clinic-01',
      reportDate: today.subtract(const Duration(days: 4)),
      reportMonth: DateTime(today.year, today.month, 1),
      totalRevenue: 4600.0,
    ),
    FinancialReportModel(
      clinicId: 'demo-clinic-01',
      reportDate: today.subtract(const Duration(days: 5)),
      reportMonth: DateTime(today.year, today.month, 1),
      totalRevenue: 2900.0,
    ),
  ];

  // بيانات شاشة تتبع دور المريض اللحظية
  static final Map<String, dynamic> patientQueueStatus = {
    'found': true,
    'appointment_id': 'appt-02',
    'ticket_number': '14',
    'patient_name': 'سارة كمال الشناوي',
    'patient_phone': '01123456789',
    'doctor_name': 'د. عبد الرحمن الزهيري',
    'doctor_title': 'استشاري جراحة العظام والمفاصل والعمود الفقري',
    'clinic_name': 'مستشفى وعيادات الأمل التخصصية',
    'branch_name': 'فرع المعادي الرئيسي - برج النخبة الطبي',
    'branch_address': 'شارع 9، ميدان المحطة، المعادي، القاهرة',
    'clinic_phone': '0223456789',
    'room_name': 'غرفة الكشف رقم 2',
    'current_queue_status': 'in_waiting_room', // arrived, in_waiting_room, in_consultation, completed
    'patients_ahead': 2,
    'estimated_wait_minutes': 15,
    'appointment_time': '11:00 ص',
    'arrival_time': '10:45 ص',
    'examination_type': 'استشارة ومتابعة أشعة',
    'vitals': {
      'blood_pressure': '120/80',
      'heart_rate': '74 bpm',
      'temperature': '37.1 °C',
      'weight': '64 kg',
    },
    'timeline_steps': [
      {'step': 1, 'title': 'حجز الموعد وتأكيده', 'time': '10:00 ص', 'done': true},
      {'step': 2, 'title': 'تسجيل الوصول بالعيادة', 'time': '10:45 ص', 'done': true},
      {'step': 3, 'title': 'في صالة الانتظار (دورك التالي)', 'time': 'الآن', 'done': true, 'active': true},
      {'step': 4, 'title': 'الدخول لغرفة الطبيب', 'time': '11:00 ص متوقع', 'done': false},
      {'step': 5, 'title': 'استلام الروشتة وإتمام الزيارة', 'time': '--', 'done': false},
    ],
  };
}
