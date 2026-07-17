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
    subscription_end_date timestamptz NOT NULL DEFAULT (now() + interval '30 days'), -- 30-day default trial
    is_active boolean NOT NULL DEFAULT true,
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
    status text NOT NULL CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')) DEFAULT 'pending',
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

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_clinic_id uuid;
  v_role public.user_role;
  v_full_name text;
  v_clinic_name text;
  v_invite_code text;
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
    INSERT INTO public.clinics (name, subscription_end_date, is_active)
    VALUES (v_clinic_name, now() + interval '30 days', true)
    RETURNING id INTO v_clinic_id;
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
  INSERT INTO public.users (id, clinic_id, role, full_name, is_active, can_delete_appointments, can_view_reports)
  VALUES (new.id, v_clinic_id, v_role, v_full_name, v_is_active, v_can_delete_appointments, v_can_view_reports);

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
    USING (clinic_id = public.get_my_clinic_id() AND public.is_my_user_active());

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
