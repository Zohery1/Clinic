# Eyadaty Feature Development & UI Redesign Guide

This guide provides developers and AI agents with the standardized process for adding new clinical features or redesigning existing screens in the **Eyadaty** codebase.

---

## 1. Feature Development Recipe

When adding a new capability (e.g., `laboratory_orders` or `invoicing`), follow this 6-step recipe:

### Step 1: Create the Feature Directory Hierarchy
```
lib/src/features/<feature_name>/
├── domain/
│   └── <entity_name>_model.dart
├── data/
│   └── <entity_name>_repository.dart
└── presentation/
    ├── <feature_name>_controller.dart
    ├── <feature_name>_screen.dart
    └── widgets/
        └── <feature_name>_subwidget.dart
```

### Step 2: Implement Domain Model
Write an immutable model with full null safety and serialisation:
```dart
class LabOrderModel {
  final String id;
  final String clinicId;
  final String patientId;
  final String testName;
  final DateTime createdAt;

  const LabOrderModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.testName,
    required this.createdAt,
  });

  factory LabOrderModel.fromJson(Map<String, dynamic> json) {
    return LabOrderModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      patientId: json['patient_id'] as String,
      testName: json['test_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clinic_id': clinicId,
    'patient_id': patientId,
    'test_name': testName,
    'created_at': createdAt.toIso8601String(),
  };
}
```

### Step 3: Implement Data Repository
Always filter by `clinic_id` to enforce multi-tenant isolation:
```dart
final labOrderRepositoryProvider = Provider<LabOrderRepository>((ref) {
  return LabOrderRepository(ref.watch(supabaseClientProvider));
});

class LabOrderRepository {
  final SupabaseClient _supabase;
  LabOrderRepository(this._supabase);

  Future<List<LabOrderModel>> getOrdersForPatient({
    required String clinicId,
    required String patientId,
  }) async {
    final data = await _supabase
        .from('lab_orders')
        .select()
        .eq('clinic_id', clinicId)
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (data as List).map((row) => LabOrderModel.fromJson(row)).toList();
  }
}
```

### Step 4: Expose Riverpod State
Expose state via an `AsyncValue` provider:
```dart
final patientLabOrdersProvider =
    FutureProvider.family<List<LabOrderModel>, ({String clinicId, String patientId})>(
  (ref, args) async {
    final repo = ref.watch(labOrderRepositoryProvider);
    return repo.getOrdersForPatient(clinicId: args.clinicId, patientId: args.patientId);
  },
);
```

### Step 5: Compose Presentation UI
Decompose the view into clean, focused subwidgets:
1. **Screen Orchestrator:** Manages lifecycle, controller watches, and high-level layout.
2. **Subcomponents:** Placed in `presentation/widgets/`. Use design tokens (`AppColors`, `AppSpace`, `AppRadii`).

### Step 6: Connect to Navigation
1. Add route name in `lib/src/core/routing/app_routes.dart`:
   ```dart
   static const labOrders = '/lab-orders';
   ```
2. Create argument class (if needed) and register in `lib/src/core/routing/app_router.dart`:
   ```dart
   case AppRoutes.labOrders:
     return MaterialPageRoute(builder: (_) => const LabOrdersScreen(...));
   ```
3. Expose helper in `lib/src/core/routing/app_navigation.dart`:
   ```dart
   static Future<T?> toLabOrders<T>(BuildContext context, {required String clinicId}) {
     return Navigator.of(context).pushNamed<T>(AppRoutes.labOrders, arguments: ...);
   }
   ```

---

## 2. Safe UI Redesign & Overhaul Workflow

In accordance with Eyadaty's architectural standards:

### The Anti-Diff-Bias Rule
When instructed to overhaul or redesign a screen:
- **Never make partial, cosmetic patches** to tangled legacy code.
- **Wipe and replace cleanly:** Completely overwrite the file from line 1 to EOF.
- **Isolate Callers First:** Because all callers route through `AppNavigation`, you do not need to worry about other screens breaking when you redesign a screen's constructor, widget tree, or internal states.

### Step-by-Step Screen Redesign
1. **Inspect Contract:** Check what arguments `AppNavigation` passes to the screen or dialog.
2. **Extract Complex Subwidgets:** Break oversized files (>400 lines) into subcomponents inside `widgets/<screen_name>/`.
3. **Rewrite Clean Orchestrator:** Implement the parent screen cleanly with high-level readability.
4. **Run Verification:** Run `flutter analyze` and `flutter test` to ensure zero compilation or regression errors.
