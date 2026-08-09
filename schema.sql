-- ==========================================
-- Multi-Tenant Clinic Management Schema
-- Database: PostgreSQL (Supabase)
-- Author: Senior Database Architect
-- ==========================================

-- Clean up existing structures (if any, for clean execution)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP TRIGGER IF EXISTS update_appointment_services_updated_at ON public.appointment_services;
DROP TRIGGER IF EXISTS update_services_updated_at ON public.services;
DROP TRIGGER IF EXISTS update_appointment_types_updated_at ON public.appointment_types;
DROP TRIGGER IF EXISTS update_visit_notes_updated_at ON public.visit_notes;
DROP TRIGGER IF EXISTS update_appointments_updated_at ON public.appointments;
DROP TRIGGER IF EXISTS update_patients_updated_at ON public.patients;
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_clinics_updated_at ON public.clinics;
DROP FUNCTION IF EXISTS public.update_updated_at_column();
DROP FUNCTION IF EXISTS public.is_my_user_active();

DROP VIEW IF EXISTS public.clinic_financial_reports;
DROP TABLE IF EXISTS public.audit_logs;
DROP TABLE IF EXISTS public.notifications;
DROP TABLE IF EXISTS public.appointment_services;
DROP TABLE IF EXISTS public.visit_notes;
DROP TABLE IF EXISTS public.appointments;
DROP TABLE IF EXISTS public.patients;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.services;
DROP TABLE IF EXISTS public.appointment_types;
DROP TABLE IF EXISTS public.clinics;
DROP TYPE IF EXISTS public.user_role;

-- 1. Custom Types
CREATE TYPE public.user_role AS ENUM ('doctor', 'secretary');

-- 2. Clinic Table (Tenant Container)
CREATE TABLE public.clinics (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    invite_code text UNIQUE NOT NULL DEFAULT substring(md5(random()::text) from 1 for 6), -- كود دعوة عشوائي مكون من 6 رموز
    subscription_end_date timestamptz NOT NULL DEFAULT now(), -- Bounded to zero until admin activates
    subscription_status text NOT NULL DEFAULT 'pending_activation' CHECK (subscription_status IN ('active', 'pending_activation', 'expired', 'suspended')),
    is_active boolean NOT NULL DEFAULT false,
    whatsapp_enabled boolean NOT NULL DEFAULT false,
    whatsapp_phone text,
    whatsapp_instance_name text,
    whatsapp_status text NOT NULL DEFAULT 'disconnected',
    send_booking_message boolean NOT NULL DEFAULT true,
    send_reminder_message boolean NOT NULL DEFAULT true,
    send_cancellation_message boolean NOT NULL DEFAULT true,
    booking_message_template text NOT NULL DEFAULT 'عزيزي المريض [patient_name]، تم تسجيل حجزك في العيادة بتاريخ [date] في تمام الساعة [time]. نتمنى لكم دوام الصحة والعافية.',
    reminder_message_template text NOT NULL DEFAULT 'تذكير: عزيزي المريض [patient_name]، موعد كشفك القادم في العيادة هو غداً [date] في تمام الساعة [time]. يرجى الحضور في الموعد المحدد.',
    cancellation_message_template text NOT NULL DEFAULT 'عزيزي المريض [patient_name]، نعتذر عن إلغاء موعدك في العيادة بتاريخ [date] لظروف طارئة بالعيادة. نتمنى لكم دوام الصحة والعافية.',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 3. Appointment Types Table (أنواع الكشوفات)
CREATE TABLE public.appointment_types (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    name text NOT NULL,
    price numeric(10, 2) NOT NULL CHECK (price >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 4. Services Table (الخدمات الإضافية)
CREATE TABLE public.services (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    name text NOT NULL,
    price numeric(10, 2) NOT NULL CHECK (price >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 5. Users Table (Linked to Supabase Auth)
CREATE TABLE public.users (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    role public.user_role NOT NULL DEFAULT 'doctor',
    full_name text NOT NULL,
    is_active boolean NOT NULL DEFAULT true,                     -- هل الحساب نشط؟ (للحظر)
    can_delete_appointments boolean NOT NULL DEFAULT false,       -- صلاحية حذف المواعيد للسكرتيرة
    can_view_reports boolean NOT NULL DEFAULT false,              -- صلاحية رؤية التقارير المالية للسكرتيرة
    can_edit_services boolean NOT NULL DEFAULT false,             -- صلاحية تعديل الخدمات والأسعار
    can_view_medical_history boolean NOT NULL DEFAULT false,       -- صلاحية رؤية الروشتة والتاريخ الطبي
    can_cancel_appointments boolean NOT NULL DEFAULT true,        -- صلاحية إلغاء المواعيد
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 6. Patients Table
CREATE TABLE public.patients (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    full_name text NOT NULL,
    phone text,
    gender text CHECK (gender IN ('male', 'female')),
    birth_date date,
    address text,
    medical_history text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 7. Appointments Table
CREATE TABLE public.appointments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    patient_id uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    appointment_type_id uuid REFERENCES public.appointment_types(id) ON DELETE SET NULL,
    appointment_date timestamptz NOT NULL,
    status text NOT NULL CHECK (status IN ('pending', 'confirmed', 'cancelled', 'cancelled_by_clinic', 'cancelled_by_patient', 'completed')) DEFAULT 'pending',
    price_charged numeric(10, 2) CHECK (price_charged >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 8. Visit Notes Table (Sensitive Medical History)
CREATE TABLE public.visit_notes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    appointment_id uuid UNIQUE NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    patient_id uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    notes text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 9. Appointment Services Table (الخدمات المقدمة في الزيارة وتكلفتها)
CREATE TABLE public.appointment_services (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    appointment_id uuid NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    service_id uuid REFERENCES public.services(id) ON DELETE SET NULL,
    price_charged numeric(10, 2) NOT NULL CHECK (price_charged >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================
-- Security Definier Helper Functions for RLS
-- ==========================================

-- Helper: Get logged-in user's clinic ID
CREATE OR REPLACE FUNCTION public.get_my_clinic_id()
RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT clinic_id FROM public.users WHERE id = auth.uid();
$$;

-- Helper: Get logged-in user's role
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.user_role
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

-- Helper: Check if current user is active (not blocked)
CREATE OR REPLACE FUNCTION public.is_my_user_active()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT coalesce(is_active, true) FROM public.users WHERE id = auth.uid();
$$;

-- Helper: Check if clinic has active subscription
CREATE OR REPLACE FUNCTION public.is_my_clinic_active()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_active AND subscription_end_date >= now()
  FROM public.clinics
  WHERE id = public.get_my_clinic_id();
$$;

-- ==========================================
-- Self-Onboarding Triggers (auth.users -> public.users)
-- ==========================================

-- Ensure users table has phone column
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone text;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_clinic_id uuid;
  v_role public.user_role;
  v_full_name text;
  v_clinic_name text;
  v_invite_code text;
  v_phone text;
  v_is_active boolean;
  v_can_delete_appointments boolean;
  v_can_view_reports boolean;
BEGIN
  -- Extract metadata from the signup request
  v_clinic_id := ((new.raw_user_meta_data ->> 'clinic_id')::uuid);
  v_role := (new.raw_user_meta_data ->> 'role')::public.user_role;
  v_full_name := coalesce(new.raw_user_meta_data ->> 'full_name', 'مستخدم جديد');
  v_clinic_name := coalesce(new.raw_user_meta_data ->> 'clinic_name', 'عيادة جديدة');
  v_invite_code := new.raw_user_meta_data ->> 'invite_code';
  v_phone := coalesce(
    nullif(new.raw_user_meta_data ->> 'phone', ''),
    nullif(new.raw_user_meta_data ->> 'user_phone', ''),
    nullif(new.raw_user_meta_data ->> 'whatsapp_phone', ''),
    nullif(new.phone::text, '')
  );

  -- Populate auth.users native phone column if null
  IF v_phone IS NOT NULL AND v_phone != '' AND (new.phone IS NULL OR new.phone = '') THEN
    UPDATE auth.users SET phone = v_phone WHERE id = new.id;
  END IF;

  -- Default role to doctor if not specified
  IF v_role IS NULL THEN
    v_role := 'doctor'::public.user_role;
  END IF;

  -- If clinic_id is null, try to find it by invite_code
  IF v_clinic_id IS NULL AND v_invite_code IS NOT NULL THEN
    SELECT id INTO v_clinic_id FROM public.clinics WHERE invite_code = v_invite_code;
  END IF;

  -- If still null, create a new clinic (Self-onboarding for doctors)
  IF v_clinic_id IS NULL THEN
    INSERT INTO public.clinics (name, whatsapp_phone, subscription_status, is_active, subscription_end_date)
    VALUES (v_clinic_name, v_phone, 'pending_activation', false, now())
    RETURNING id INTO v_clinic_id;
  ELSE
    -- If doctor joining existing clinic, save phone to clinic if missing
    IF v_role = 'doctor' AND v_phone IS NOT NULL THEN
      UPDATE public.clinics SET whatsapp_phone = v_phone WHERE id = v_clinic_id AND (whatsapp_phone IS NULL OR whatsapp_phone = '');
    END IF;
  END IF;

  -- Set default permissions based on role
  IF v_role = 'doctor' THEN
    v_is_active := true;
    v_can_delete_appointments := true;
    v_can_view_reports := true;
  ELSE
    v_is_active := true;
    v_can_delete_appointments := false; -- السكرتيرة لا تحذف مواعيد افتراضياً
    v_can_view_reports := false;        -- السكرتيرة لا ترى التقارير افتراضياً
  END IF;

  -- Insert profile
  INSERT INTO public.users (id, clinic_id, role, full_name, phone, is_active, can_delete_appointments, can_view_reports)
  VALUES (new.id, v_clinic_id, v_role, v_full_name, v_phone, v_is_active, v_can_delete_appointments, v_can_view_reports);

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Bind onboarding function to auth.users trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- Enabling Row-Level Security (RLS)
-- ==========================================

ALTER TABLE public.clinics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visit_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_services ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Row-Level Security Policies
-- ==========================================

-- 1. Clinics Policies
CREATE POLICY "Users can read their own clinic" ON public.clinics
    FOR SELECT TO authenticated
    USING (id = public.get_my_clinic_id() AND public.is_my_user_active());

CREATE POLICY "Doctors can update their clinic settings" ON public.clinics
    FOR UPDATE TO authenticated
    USING (id = public.get_my_clinic_id() AND public.get_my_role() = 'doctor' AND public.is_my_user_active());

-- 2. Appointment Types Policies
CREATE POLICY "Users can view appointment types in their clinic" ON public.appointment_types
    FOR SELECT TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active());

CREATE POLICY "Doctors can manage appointment types in their clinic" ON public.appointment_types
    FOR ALL TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.get_my_role() = 'doctor' AND public.is_my_user_active());

-- 3. Services Policies
CREATE POLICY "Users can view services in their clinic" ON public.services
    FOR SELECT TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active());

CREATE POLICY "Doctors can manage services in their clinic" ON public.services
    FOR ALL TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.get_my_role() = 'doctor' AND public.is_my_user_active());

-- 4. Users (Profiles) Policies
CREATE POLICY "Users can view profiles in the same clinic" ON public.users
    FOR SELECT TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active());

CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE TO authenticated
    USING (id = auth.uid() AND public.is_my_user_active())
    WITH CHECK (id = auth.uid());

CREATE POLICY "Doctors can manage profiles in their clinic" ON public.users
    FOR ALL TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.get_my_role() = 'doctor' AND public.is_my_user_active());

-- 5. Patients Policies
CREATE POLICY "Users can view patients in their clinic" ON public.patients
    FOR SELECT TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active());

CREATE POLICY "Users can create patients if subscription active" ON public.patients
    FOR INSERT TO authenticated
    WITH CHECK (clinic_id = public.get_my_clinic_id() AND public.is_my_clinic_active() AND public.is_my_user_active());

CREATE POLICY "Users can update patients if subscription active" ON public.patients
    FOR UPDATE TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active())
    WITH CHECK (clinic_id = public.get_my_clinic_id() AND public.is_my_clinic_active());

CREATE POLICY "Doctors can delete patients if subscription active" ON public.patients
    FOR DELETE TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.get_my_role() = 'doctor' AND public.is_my_clinic_active() AND public.is_my_user_active());

-- 6. Appointments Policies
CREATE POLICY "Users can view appointments in their clinic" ON public.appointments
    FOR SELECT TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active());

CREATE POLICY "Users can book/update appointments if subscription active" ON public.appointments
    FOR INSERT TO authenticated
    WITH CHECK (clinic_id = public.get_my_clinic_id() AND public.is_my_clinic_active() AND public.is_my_user_active());

CREATE POLICY "Users can edit appointments if subscription active" ON public.appointments
    FOR UPDATE TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active())
    WITH CHECK (clinic_id = public.get_my_clinic_id() AND public.is_my_clinic_active());

CREATE POLICY "Doctors/Authorized can delete appointments if subscription active" ON public.appointments
    FOR DELETE TO authenticated
    USING (
        clinic_id = public.get_my_clinic_id() 
        AND public.is_my_clinic_active() 
        AND public.is_my_user_active()
        AND (
            public.get_my_role() = 'doctor' 
            OR (SELECT can_delete_appointments FROM public.users WHERE id = auth.uid())
        )
    );

-- 7. Visit Notes Policies
CREATE POLICY "Users can view notes in their clinic" ON public.visit_notes
    FOR SELECT TO authenticated
    USING (
        clinic_id = public.get_my_clinic_id() 
        AND public.is_my_user_active()
        AND (
            public.get_my_role() = 'doctor' 
            OR (SELECT can_view_medical_history FROM public.users WHERE id = auth.uid())
        )
    );

CREATE POLICY "Doctors can insert notes if subscription active" ON public.visit_notes
    FOR INSERT TO authenticated
    WITH CHECK (
        clinic_id = public.get_my_clinic_id() 
        AND public.get_my_role() = 'doctor' 
        AND public.is_my_clinic_active()
        AND public.is_my_user_active()
    );

CREATE POLICY "Doctors can edit notes if subscription active" ON public.visit_notes
    FOR UPDATE TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.get_my_role() = 'doctor' AND public.is_my_user_active())
    WITH CHECK (
        clinic_id = public.get_my_clinic_id() 
        AND public.get_my_role() = 'doctor' 
        AND public.is_my_clinic_active()
    );

CREATE POLICY "Doctors can delete notes if subscription active" ON public.visit_notes
    FOR DELETE TO authenticated
    USING (
        clinic_id = public.get_my_clinic_id() 
        AND public.get_my_role() = 'doctor' 
        AND public.is_my_clinic_active()
        AND public.is_my_user_active()
    );

-- 8. Appointment Services Policies
CREATE POLICY "Users can view appointment services in their clinic" ON public.appointment_services
    FOR SELECT TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active());

CREATE POLICY "Users can manage appointment services if subscription active" ON public.appointment_services
    FOR ALL TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_clinic_active() AND public.is_my_user_active());

-- ==========================================
-- Automatically update updated_at Column
-- ==========================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_clinics_updated_at BEFORE UPDATE ON public.clinics FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_appointment_types_updated_at BEFORE UPDATE ON public.appointment_types FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON public.services FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON public.patients FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_visit_notes_updated_at BEFORE UPDATE ON public.visit_notes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_appointment_services_updated_at BEFORE UPDATE ON public.appointment_services FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- Financial View for Reports
-- ==========================================

CREATE OR REPLACE VIEW public.clinic_financial_reports AS
SELECT 
    clinic_id,
    transaction_date::date as report_date,
    date_trunc('month', transaction_date)::date as report_month,
    sum(amount) as total_revenue
FROM (
    -- Revenue from completed appointments (کشف طبي)
    SELECT clinic_id, appointment_date as transaction_date, coalesce(price_charged, 0) as amount 
    FROM public.appointments 
    WHERE status = 'completed'
    
    UNION ALL
    
    -- Revenue from services in completed appointments
    SELECT aps.clinic_id, app.appointment_date as transaction_date, coalesce(aps.price_charged, 0) as amount 
    FROM public.appointment_services aps
    JOIN public.appointments app ON aps.appointment_id = app.id
    WHERE app.status = 'completed'
) transactions
WHERE (
    -- التحقق من الصلاحيات: الطبيب أو سكرتيرة تملك صلاحية رؤية التقارير
    SELECT (role = 'doctor' OR can_view_reports) 
    FROM public.users 
    WHERE id = auth.uid() AND is_active = true
)
GROUP BY clinic_id, transaction_date::date, date_trunc('month', transaction_date)::date;

-- ==========================================
-- 10. Notifications Table & Automated Triggers
-- ==========================================

CREATE TABLE public.notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    title text NOT NULL,
    body text NOT NULL,
    is_read boolean NOT NULL DEFAULT false,
    target_role text, -- 'doctor' or 'secretary'
    created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view notifications in their clinic" ON public.notifications
    FOR SELECT TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active());

CREATE POLICY "Users can update notifications in their clinic" ON public.notifications
    FOR UPDATE TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active())
    WITH CHECK (clinic_id = public.get_my_clinic_id());

CREATE POLICY "Users can insert notifications" ON public.notifications
    FOR INSERT TO authenticated
    WITH CHECK (clinic_id = public.get_my_clinic_id());

CREATE POLICY "Users can delete notifications" ON public.notifications
    FOR DELETE TO authenticated
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active());

-- Trigger function for new appointments (Notifies Doctor when Secretary books)
CREATE OR REPLACE FUNCTION public.on_appointment_created_notify()
RETURNS trigger AS $$
DECLARE
  v_patient_name text;
BEGIN
  SELECT full_name INTO v_patient_name FROM public.patients WHERE id = new.patient_id;
  
  INSERT INTO public.notifications (clinic_id, title, body, target_role)
  VALUES (
    new.clinic_id,
    'حجز جديد',
    'تم تسجيل حجز جديد للمريض (' || coalesce(v_patient_name, 'مريض غير معروف') || ') بتاريخ ' || to_char(new.appointment_date AT TIME ZONE 'UTC' AT TIME ZONE 'Africa/Cairo', 'YYYY-MM-DD HH24:MI'),
    'doctor'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_appointment_created_notify
  AFTER INSERT ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.on_appointment_created_notify();

-- Trigger function for new appointment services (Notifies Secretary when Doctor adds services)
CREATE OR REPLACE FUNCTION public.on_appointment_service_created_notify()
RETURNS trigger AS $$
DECLARE
  v_patient_name text;
  v_service_name text;
BEGIN
  SELECT p.full_name INTO v_patient_name
  FROM public.appointments a
  JOIN public.patients p ON a.patient_id = p.id
  WHERE a.id = new.appointment_id;

  SELECT name INTO v_service_name FROM public.services WHERE id = new.service_id;

  INSERT INTO public.notifications (clinic_id, title, body, target_role)
  VALUES (
    new.clinic_id,
    'إضافة خدمة طبية',
    'قام الدكتور بإضافة خدمة (' || coalesce(v_service_name, 'خدمة إضافية') || ') للمريض (' || coalesce(v_patient_name, 'مريض') || ')',
    'secretary'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_appointment_service_created_notify
  AFTER INSERT ON public.appointment_services
  FOR EACH ROW EXECUTE FUNCTION public.on_appointment_service_created_notify();

-- Trigger function for appointment status changes (Pending -> Doctor, Completed -> Secretary)
CREATE OR REPLACE FUNCTION public.on_appointment_status_changed_notify()
RETURNS trigger AS $$
DECLARE
  v_patient_name text;
BEGIN
  IF old.status IS DISTINCT FROM new.status THEN
    SELECT full_name INTO v_patient_name FROM public.patients WHERE id = new.patient_id;

    -- When Secretary moves patient to 'pending' (مع الطبيب), notify Doctor
    IF new.status = 'pending' THEN
      INSERT INTO public.notifications (clinic_id, title, body, target_role)
      VALUES (
        new.clinic_id,
        'دخول مريض للفحص',
        'المريض (' || coalesce(v_patient_name, 'مريض') || ') في انتظارك الآن بغرفة الكشف',
        'doctor'
      );
    -- When Doctor completes examination ('completed'), notify Secretary
    ELSIF new.status = 'completed' THEN
      INSERT INTO public.notifications (clinic_id, title, body, target_role)
      VALUES (
        new.clinic_id,
        'إتمام كشف مريض',
        'أنهى الدكتور كشف المريض (' || coalesce(v_patient_name, 'مريض') || ')',
        'secretary'
      );
    END IF;
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_appointment_status_changed_notify
  AFTER UPDATE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.on_appointment_status_changed_notify();

-- ==========================================
-- 11. Audit Logs Table & Security Triggers
-- ==========================================

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    actor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    action text NOT NULL,
    target_table text NOT NULL,
    target_id uuid,
    details jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Only Doctors or users with can_view_reports can view audit logs
CREATE POLICY "Doctors and authorized users can view audit logs" ON public.audit_logs
    FOR SELECT TO authenticated
    USING (
        clinic_id = public.get_my_clinic_id() 
        AND public.is_my_user_active()
        AND (
            public.get_my_role() = 'doctor' 
            OR (SELECT can_view_reports FROM public.users WHERE id = auth.uid())
        )
    );

-- Trigger function for audit logging sensitive operations (DELETE / UPDATE on appointments & patients)
CREATE OR REPLACE FUNCTION public.log_sensitive_action()
RETURNS trigger AS $$
DECLARE
  v_clinic_id uuid;
  v_actor_id uuid;
  v_target_id uuid;
BEGIN
  v_actor_id := auth.uid();
  IF TG_OP = 'DELETE' THEN
    v_clinic_id := OLD.clinic_id;
    v_target_id := OLD.id;
    INSERT INTO public.audit_logs (clinic_id, actor_id, action, target_table, target_id, details)
    VALUES (v_clinic_id, v_actor_id, 'DELETE', TG_TABLE_NAME, v_target_id, to_jsonb(OLD));
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    v_clinic_id := NEW.clinic_id;
    v_target_id := NEW.id;
    INSERT INTO public.audit_logs (clinic_id, actor_id, action, target_table, target_id, details)
    VALUES (v_clinic_id, v_actor_id, 'UPDATE', TG_TABLE_NAME, v_target_id, jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW)));
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER audit_appointments_changes
  AFTER UPDATE OR DELETE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.log_sensitive_action();

CREATE TRIGGER audit_patients_changes
  AFTER UPDATE OR DELETE ON public.patients
  FOR EACH ROW EXECUTE FUNCTION public.log_sensitive_action();

-- ==========================================
-- Super Admin RPC Functions (Bypass RLS for Admin Dashboard)
-- ==========================================

-- 1. Get All Clinics for Super Admin Dashboard (SECURITY DEFINER to bypass RLS)
CREATE OR REPLACE FUNCTION public.get_all_clinics_for_admin()
RETURNS TABLE (
    id uuid,
    name text,
    invite_code text,
    subscription_end_date timestamptz,
    subscription_status text,
    is_active boolean,
    created_at timestamptz,
    whatsapp_phone text,
    doctor_name text,
    doctor_email text,
    doctor_phone text,
    patient_count bigint,
    appointment_count bigint,
    users_data jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.invite_code,
        c.subscription_end_date,
        c.subscription_status,
        c.is_active,
        c.created_at,
        c.whatsapp_phone,
        coalesce((SELECT u.full_name FROM public.users u WHERE u.clinic_id = c.id AND u.role = 'doctor' LIMIT 1), 'غير محدد') as doctor_name,
        coalesce((
          SELECT au.email::text 
          FROM public.users u 
          JOIN auth.users au ON au.id = u.id 
          WHERE u.clinic_id = c.id AND u.role = 'doctor' 
          LIMIT 1
        ), '') as doctor_email,
        coalesce(
          (
            SELECT coalesce(
              nullif(u.phone, ''),
              nullif(au.phone::text, ''),
              nullif(au.raw_user_meta_data ->> 'phone', ''),
              nullif(au.raw_user_meta_data ->> 'whatsapp_phone', '')
            )
            FROM public.users u
            JOIN auth.users au ON au.id = u.id
            WHERE u.clinic_id = c.id AND u.role = 'doctor'
            LIMIT 1
          ),
          nullif(c.whatsapp_phone, ''),
          ''
        ) as doctor_phone,
        (SELECT count(*) FROM public.patients p WHERE p.clinic_id = c.id) as patient_count,
        (SELECT count(*) FROM public.appointments a WHERE a.clinic_id = c.id) as appointment_count,
        coalesce((
          SELECT jsonb_agg(
            jsonb_build_object(
              'id', u.id,
              'full_name', u.full_name,
              'role', u.role,
              'phone', coalesce(nullif(u.phone, ''), nullif(au.phone::text, ''), nullif(au.raw_user_meta_data ->> 'phone', '')),
              'can_delete_appointments', u.can_delete_appointments,
              'can_view_reports', u.can_view_reports
            )
          )
          FROM public.users u
          LEFT JOIN auth.users au ON au.id = u.id
          WHERE u.clinic_id = c.id
        ), '[]'::jsonb) as users_data
    FROM public.clinics c
    ORDER BY c.created_at DESC;
END;
$$;

-- 5. Admin Update Doctor Phone Number (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.admin_update_doctor_phone(p_clinic_id uuid, p_phone text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update clinic's whatsapp phone
    UPDATE public.clinics
    SET whatsapp_phone = p_phone
    WHERE id = p_clinic_id;

    -- Update doctor's profile phone
    UPDATE public.users
    SET phone = p_phone
    WHERE clinic_id = p_clinic_id AND role = 'doctor';

    -- Update auth.users native phone & metadata
    UPDATE auth.users au
    SET 
      phone = p_phone,
      raw_user_meta_data = jsonb_set(coalesce(au.raw_user_meta_data, '{}'::jsonb), '{phone}', to_jsonb(p_phone))
    FROM public.users u
    WHERE u.id = au.id AND u.clinic_id = p_clinic_id AND u.role = 'doctor';
END;
$$;

-- 2. 1-Click Activate Pending Clinic (+30 days)
CREATE OR REPLACE FUNCTION public.admin_activate_clinic(p_clinic_id uuid, p_days int DEFAULT 30)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.clinics
    SET 
        subscription_status = 'active',
        is_active = true,
        subscription_end_date = (now() + (p_days || ' days')::interval)
    WHERE id = p_clinic_id;
END;
$$;

-- 3. Extend Clinic Subscription
CREATE OR REPLACE FUNCTION public.admin_extend_clinic(p_clinic_id uuid, p_end_date timestamptz)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.clinics
    SET 
        subscription_status = 'active',
        is_active = true,
        subscription_end_date = p_end_date
    WHERE id = p_clinic_id;
END;
$$;

-- 4. Toggle Clinic Active / Suspended State
CREATE OR REPLACE FUNCTION public.admin_toggle_clinic_active(p_clinic_id uuid, p_is_active boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.clinics
    SET 
        is_active = p_is_active,
        subscription_status = CASE WHEN p_is_active THEN 'active' ELSE 'suspended' END
    WHERE id = p_clinic_id;
END;
$$;

-- 5. Delete Clinic (Cascades all data AND deletes associated auth.users accounts)
CREATE OR REPLACE FUNCTION public.admin_delete_clinic(p_clinic_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_ids uuid[];
BEGIN
    -- Extract all user IDs linked to this clinic
    SELECT array_agg(u.id) INTO v_user_ids
    FROM public.users u
    WHERE u.clinic_id = p_clinic_id;

    -- Delete associated users from auth.users schema FIRST
    IF v_user_ids IS NOT NULL AND array_length(v_user_ids, 1) > 0 THEN
      DELETE FROM auth.users WHERE id = ANY(v_user_ids);
    END IF;

    -- Delete clinic row (cascades all remaining public tables)
    DELETE FROM public.clinics WHERE id = p_clinic_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_delete_clinic(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_all_clinics_for_admin() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_activate_clinic(uuid, int) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_extend_clinic(uuid, timestamptz) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_toggle_clinic_active(uuid, boolean) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_delete_clinic(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_all_clinics_for_admin() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_activate_clinic(uuid, int) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_extend_clinic(uuid, timestamptz) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_toggle_clinic_active(uuid, boolean) TO authenticated, service_role;

-- ==========================================
-- 12. High-Performance Indexes for 1000% Speed
-- ==========================================

-- 1. Appointments Indexes
CREATE INDEX IF NOT EXISTS idx_appointments_clinic_date_status 
ON public.appointments (clinic_id, appointment_date, status);

CREATE INDEX IF NOT EXISTS idx_appointments_patient 
ON public.appointments (clinic_id, patient_id);

CREATE INDEX IF NOT EXISTS idx_appointments_completed_revenue 
ON public.appointments (clinic_id, appointment_date) 
WHERE status = 'completed';

-- 2. Patients Indexes
CREATE INDEX IF NOT EXISTS idx_patients_clinic_created 
ON public.patients (clinic_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_patients_clinic_phone 
ON public.patients (clinic_id, phone);

CREATE INDEX IF NOT EXISTS idx_patients_clinic_name 
ON public.patients (clinic_id, full_name);

-- 3. Appointment Services & Visit Notes Indexes
CREATE INDEX IF NOT EXISTS idx_appointment_services_app 
ON public.appointment_services (clinic_id, appointment_id);

CREATE INDEX IF NOT EXISTS idx_visit_notes_patient 
ON public.visit_notes (clinic_id, patient_id);

CREATE INDEX IF NOT EXISTS idx_visit_notes_appointment 
ON public.visit_notes (clinic_id, appointment_id);

-- 4. Notifications & Audit Logs Indexes
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS target_role text;

CREATE INDEX IF NOT EXISTS idx_notifications_clinic_target 
ON public.notifications (clinic_id, is_read, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_clinic_created 
ON public.audit_logs (clinic_id, created_at DESC);

-- 5. Users & Clinics Indexes
CREATE INDEX IF NOT EXISTS idx_users_clinic_role 
ON public.users (clinic_id, role, is_active);

CREATE INDEX IF NOT EXISTS idx_clinics_status_active 
ON public.clinics (subscription_status, is_active);




