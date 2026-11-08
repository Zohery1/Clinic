# Eyadaty Security & Multi-Tenancy Architecture

This document outlines the security architecture, multi-tenant isolation model, Role-Based Access Control (RBAC), and patient privacy protections implemented in the **Eyadaty** clinical platform.

---

## 1. Multi-Tenant Isolation Model

Eyadaty is an enterprise multi-tenant software system where multiple medical clinics share the same infrastructure and database while maintaining strict logical and cryptographic data isolation.

### The Tenant Key: `clinic_id`
Every business record in the database contains an indexed `clinic_id` column:
- `patients`
- `appointments`
- `visit_notes`
- `services`
- `clinic_branches`
- `clinic_users`
- `petty_expenses`

### Principles of Isolation
1. **Query-Level Enforcement:** All repository methods must explicitly bind queries to the active user's `clinicId`:
   ```dart
   final response = await _supabase
       .from('patients')
       .select()
       .eq('clinic_id', clinicId)
       .order('created_at');
   ```
2. **Row-Level Security (RLS) as Ground Truth:** Even if a client query accidentally omits the `clinic_id` filter or attempts to pass a foreign `clinic_id`, Supabase Postgres RLS policies reject the operation at the database engine level.

---

## 2. Supabase Row Level Security (RLS)

All public tables have RLS enabled (`ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;`).

### Tenant Verification Policy Example
```sql
CREATE POLICY "Clinic isolation policy for patients"
ON public.patients
FOR ALL
USING (
  clinic_id IN (
    SELECT cu.clinic_id 
    FROM public.clinic_users cu 
    WHERE cu.user_id = auth.uid() AND cu.status = 'active'
  )
)
WITH CHECK (
  clinic_id IN (
    SELECT cu.clinic_id 
    FROM public.clinic_users cu 
    WHERE cu.user_id = auth.uid() AND cu.status = 'active'
  )
);
```

---

## 3. Role-Based Access Control (RBAC)

Eyadaty implements strict role segregation across clinical, administrative, and financial functions.

### Supported Roles
1. **`admin` (Clinic Owner / Medical Director):**
   - Full access to all modules: financial reports, cash drawer reconciliation, staff management, role assignment, branch configuration, WhatsApp automation settings, and subscription management.
2. **`doctor` (Clinical Practitioner):**
   - Access to today's queue, patient clinical history, vitals, examination screen, prescription generation, visit notes, and patient profile details.
   - Restricted from viewing other clinics' financial analytics or modifying clinic settings.
3. **`secretary` (Front Desk / Intake Staff):**
   - Access to patient registration, fast intake (`BookAppointmentDialog`), queue check-in/walk-in admission, daily visit logs, and WhatsApp notification dispatching.
   - Restricted from editing clinical visit notes or diagnostic examination reports.

### UI Role Guarding
Views and action controls reflect the active user's role via `UserModel.role` and `UserModel.isDoctor`:
```dart
if (status == 'completed' && isDoctor)
  AppButton(
    label: 'عرض التقرير',
    onPressed: () => AppNavigation.toExamination(...),
  );
```

---

## 4. Authentication, Session & Gate Architecture

1. **Authentication Gate (`AuthGate`):**
   - Watches `authStateProvider`. If unauthenticated, routes to `LoginScreen`.
   - Checks user clinic association: users without a clinic are directed to the clinic join or creation flow.
2. **Status Verification Gates:**
   - `pending_activation`: Displays `PendingActivationScreen` until the clinic administrator approves the account.
   - `blocked`: Renders `AccountBlockedScreen` preventing unauthorized data access.
   - `expired`: Prompts `SubscriptionGateScreen` with tier upgrade options.
3. **Token Management:**
   - Supabase Auth handles automatic JWT refresh. Tokens are securely stored using platform keystore/keychain storage.

---

## 5. Patient Privacy & Data Protection

- **Clinical Notes Segregation:** Sensitive examination diagnoses and prescriptions are saved in dedicated `visit_notes` records accessible only to authorized medical practitioners.
- **BiDi & Notification Sanitization:** Broadcast notifications sent across clinic devices omit raw clinical diagnosis text to prevent shoulder-surfing in public waiting areas.
- **WhatsApp Automation Protection:** WhatsApp message templates do not store or send full medical histories over third-party channels; messages are limited to appointment reminders, queue tokens, and clinic intake confirmations.
