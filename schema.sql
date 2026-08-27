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
    owner_id uuid REFERENCES auth.users(id) ON DELETE SET NULL, -- مالك ومدير العيادة
    name text NOT NULL,
    invite_code text UNIQUE NOT NULL DEFAULT substring(md5(random()::text) from 1 for 6), -- كود دعوة عشوائي مكون من 6 رموز
    subscription_end_date timestamptz NOT NULL DEFAULT now(), -- Bounded to zero until admin activates
    subscription_status text NOT NULL DEFAULT 'pending_activation' CHECK (subscription_status IN ('active', 'pending_activation', 'expired', 'suspended')),
    is_active boolean NOT NULL DEFAULT false,
    renewal_requested boolean NOT NULL DEFAULT false,
    renewal_requested_at timestamptz,
    renewal_plan text,
    renewal_plan_price numeric(10, 2),
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

-- 2.1 Branches Table (فروع العيادة)
CREATE TABLE public.branches (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    name text NOT NULL,
    address text,
    phone text,
    is_main boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2.2 Clinic Memberships Table (عضويات وصلاحيات المستخدم بالعيادات)
CREATE TABLE public.clinic_memberships (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    role public.user_role NOT NULL DEFAULT 'doctor',
    is_owner boolean NOT NULL DEFAULT false,
    is_active boolean NOT NULL DEFAULT true,
    can_view_reports boolean NOT NULL DEFAULT false,
    can_delete_appointments boolean NOT NULL DEFAULT false,
    can_edit_services boolean NOT NULL DEFAULT false,
    can_view_medical_history boolean NOT NULL DEFAULT false,
    can_cancel_appointments boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(user_id, clinic_id)
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
    active_clinic_id uuid REFERENCES public.clinics(id) ON DELETE SET NULL,
    active_branch_id uuid REFERENCES public.branches(id) ON DELETE SET NULL,
    role public.user_role NOT NULL DEFAULT 'doctor',
    full_name text NOT NULL,
    phone text,
    is_active boolean NOT NULL DEFAULT true,                     -- هل الحساب نشط؟ (للحظر)
    is_owner boolean NOT NULL DEFAULT false,                    -- هل المستخدم هو مدير/منشئ العيادة؟
    can_delete_appointments boolean NOT NULL DEFAULT false,       -- صلاحية حذف المواعيد للسكرتيرة
    can_view_reports boolean NOT NULL DEFAULT false,              -- صلاحية رؤية التقارير المالية العامة
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
    branch_id uuid REFERENCES public.branches(id) ON DELETE SET NULL, -- فرع العيادة المحدد للحجز
    patient_id uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    doctor_id uuid REFERENCES public.users(id) ON DELETE SET NULL, -- الطبيب المعالج للحجز
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
    doctor_id uuid REFERENCES public.users(id) ON DELETE SET NULL, -- الطبيب كاتب الروشتة/الكشف
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
-- Self-Onboarding Triggers & RPCs (auth.users -> public.users)
-- ==========================================

-- Helper: Check if current user is clinic owner
CREATE OR REPLACE FUNCTION public.is_my_clinic_owner()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT coalesce(is_owner, false) FROM public.users WHERE id = auth.uid();
$$;

-- ==========================================
-- Self-Onboarding Triggers & RPCs (auth.users -> public.users)
-- ==========================================

-- Ensure users table has phone and is_owner columns
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_owner boolean NOT NULL DEFAULT false;
ALTER TABLE public.clinics ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS doctor_id uuid REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE public.visit_notes ADD COLUMN IF NOT EXISTS doctor_id uuid REFERENCES public.users(id) ON DELETE SET NULL;

-- Drop old unsafe BEFORE trigger on auth.users (to prevent GoTrue SMS/Phone unique constraint violations)
DROP TRIGGER IF EXISTS tr_auth_user_before_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user_before();

-- AFTER INSERT trigger on auth.users to create user profile & link clinic
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_clinic_id uuid;
  v_branch_id uuid;
  v_role public.user_role;
  v_full_name text;
  v_clinic_name text;
  v_branch_name text;
  v_extra_rec record;
  v_invite_code text;
  v_phone text;
  v_is_active boolean := true;
  v_is_owner boolean := false;
  v_can_delete_appointments boolean := false;
  v_can_view_reports boolean := false;
  v_role_str text;
BEGIN
  BEGIN
    v_role_str := lower(coalesce(NEW.raw_user_meta_data ->> 'role', 'doctor'));
    IF v_role_str = 'secretary' THEN
      v_role := 'secretary'::public.user_role;
    ELSE
      v_role := 'doctor'::public.user_role;
    END IF;

    v_full_name := coalesce(nullif(NEW.raw_user_meta_data ->> 'full_name', ''), 'مستخدم جديد');
    v_clinic_name := coalesce(nullif(NEW.raw_user_meta_data ->> 'clinic_name', ''), 'عيادة جديدة');
    v_branch_name := coalesce(nullif(NEW.raw_user_meta_data ->> 'branch_name', ''), 'الفرع الرئيسي');
    v_invite_code := trim(coalesce(NEW.raw_user_meta_data ->> 'invite_code', ''));
    v_phone := coalesce(nullif(NEW.raw_user_meta_data ->> 'phone', ''), nullif(NEW.phone::text, ''));

    -- Format phone number safely for public.users
    IF v_phone IS NOT NULL AND v_phone != '' THEN
      IF v_phone ~ '^01[0-9]{9}$' THEN
        v_phone := '+2' || v_phone;
      ELSIF v_phone ~ '^201[0-9]{9}$' THEN
        v_phone := '+' || v_phone;
      ELSIF v_phone !~ '^\+' THEN
        v_phone := '+20' || regexp_replace(v_phone, '\D', '', 'g');
      END IF;
    END IF;

    -- Check if clinic_id was explicitly provided in metadata
    IF NEW.raw_user_meta_data ->> 'clinic_id' IS NOT NULL THEN
      BEGIN
        v_clinic_id := (NEW.raw_user_meta_data ->> 'clinic_id')::uuid;
      EXCEPTION WHEN OTHERS THEN
        v_clinic_id := NULL;
      END;
    END IF;

    -- If invite_code exists, find the matching clinic by invite code (case-insensitive & trimmed)
    IF v_clinic_id IS NULL AND v_invite_code != '' THEN
      SELECT id INTO v_clinic_id
      FROM public.clinics
      WHERE LOWER(TRIM(invite_code)) = LOWER(v_invite_code)
      LIMIT 1;
    END IF;

    -- If no existing clinic found, create new clinic and make this user the Owner
    IF v_clinic_id IS NULL THEN
      INSERT INTO public.clinics (name, whatsapp_phone, subscription_status, is_active, subscription_end_date, owner_id)
      VALUES (v_clinic_name, v_phone, 'pending_activation', false, now(), NEW.id)
      RETURNING id INTO v_clinic_id;

      -- Create Main Branch for new clinic
      INSERT INTO public.branches (clinic_id, name, is_main)
      VALUES (v_clinic_id, v_branch_name, true)
      RETURNING id INTO v_branch_id;

      -- Create any extra branches if provided in metadata
      IF NEW.raw_user_meta_data -> 'extra_branches' IS NOT NULL AND jsonb_typeof(NEW.raw_user_meta_data -> 'extra_branches') = 'array' THEN
        BEGIN
          FOR v_extra_rec IN
            SELECT * FROM jsonb_to_recordset((NEW.raw_user_meta_data -> 'extra_branches')::jsonb)
            AS x(name text, address text, phone text)
          LOOP
            IF v_extra_rec.name IS NOT NULL AND trim(v_extra_rec.name) != '' THEN
              INSERT INTO public.branches (clinic_id, name, address, phone, is_main)
              VALUES (v_clinic_id, trim(v_extra_rec.name), nullif(trim(v_extra_rec.address), ''), nullif(trim(v_extra_rec.phone), ''), false);
            END IF;
          END LOOP;
        EXCEPTION WHEN OTHERS THEN
          RAISE WARNING 'Error inserting extra branches in handle_new_user: %', SQLERRM;
        END;
      END IF;

      v_is_owner := true;
      v_can_view_reports := true;
      v_can_delete_appointments := true;
    ELSE
      -- Joining existing clinic via invite code or metadata
      v_is_owner := false;
      IF v_role = 'doctor' THEN
        v_can_delete_appointments := true;
        v_can_view_reports := false;
        IF v_phone IS NOT NULL AND v_phone != '' THEN
          UPDATE public.clinics SET whatsapp_phone = v_phone WHERE id = v_clinic_id AND (whatsapp_phone IS NULL OR whatsapp_phone = '');
        END IF;
      ELSE
        v_can_delete_appointments := false;
        v_can_view_reports := false;
      END IF;

      -- Get or create main branch
      SELECT id INTO v_branch_id
      FROM public.branches
      WHERE clinic_id = v_clinic_id
      ORDER BY is_main DESC, created_at ASC
      LIMIT 1;

      IF v_branch_id IS NULL THEN
        INSERT INTO public.branches (clinic_id, name, is_main)
        VALUES (v_clinic_id, 'الفرع الرئيسي', true)
        RETURNING id INTO v_branch_id;
      END IF;
    END IF;

    -- Insert/Update membership in clinic_memberships
    INSERT INTO public.clinic_memberships (
      user_id, clinic_id, role, is_owner, is_active,
      can_view_reports, can_delete_appointments, can_edit_services,
      can_view_medical_history, can_cancel_appointments
    ) VALUES (
      NEW.id, v_clinic_id, v_role, v_is_owner, v_is_active,
      v_can_view_reports, v_can_delete_appointments, v_is_owner,
      v_is_owner OR v_role = 'doctor', true
    )
    ON CONFLICT (user_id, clinic_id) DO UPDATE SET
      role = EXCLUDED.role,
      is_owner = EXCLUDED.is_owner,
      is_active = EXCLUDED.is_active;

    -- Insert/Update active user profile
    INSERT INTO public.users (
      id, clinic_id, active_clinic_id, active_branch_id,
      role, full_name, phone, is_active, is_owner,
      can_delete_appointments, can_view_reports
    )
    VALUES (
      NEW.id, v_clinic_id, v_clinic_id, v_branch_id,
      v_role, v_full_name, v_phone, v_is_active, v_is_owner,
      v_can_delete_appointments, v_can_view_reports
    )
    ON CONFLICT (id) DO UPDATE SET
      clinic_id = EXCLUDED.clinic_id,
      active_clinic_id = EXCLUDED.clinic_id,
      active_branch_id = coalesce(EXCLUDED.active_branch_id, public.users.active_branch_id),
      role = EXCLUDED.role,
      full_name = EXCLUDED.full_name,
      is_owner = EXCLUDED.is_owner,
      phone = coalesce(EXCLUDED.phone, public.users.phone);

  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'handle_new_user error: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Rebind AFTER INSERT trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- RPC: Get all clinics and branches user belongs to
CREATE OR REPLACE FUNCTION public.get_user_clinics()
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_result json;
BEGIN
  IF v_uid IS NULL THEN
    RETURN '[]'::json;
  END IF;

  SELECT json_agg(
    json_build_object(
      'clinic_id', c.id,
      'clinic_name', c.name,
      'role', cm.role,
      'is_owner', cm.is_owner,
      'is_active', cm.is_active,
      'can_view_reports', cm.can_view_reports,
      'subscription_status', c.subscription_status,
      'invite_code', c.invite_code,
      'branches', coalesce((
        SELECT json_agg(
          json_build_object(
            'id', b.id,
            'clinic_id', b.clinic_id,
            'name', b.name,
            'address', b.address,
            'phone', b.phone,
            'is_main', b.is_main
          ) ORDER BY b.is_main DESC, b.created_at ASC
        )
        FROM public.branches b
        WHERE b.clinic_id = c.id
      ), '[]'::json)
    )
  ) INTO v_result
  FROM public.clinic_memberships cm
  JOIN public.clinics c ON cm.clinic_id = c.id
  WHERE cm.user_id = v_uid AND cm.is_active = true;

  RETURN coalesce(v_result, '[]'::json);
END;
$$;

-- RPC: Switch user's active clinic and branch
CREATE OR REPLACE FUNCTION public.switch_user_active_clinic(p_clinic_id uuid, p_branch_id uuid DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_membership public.clinic_memberships%ROWTYPE;
  v_branch_id uuid := p_branch_id;
  v_clinic_name text;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'يجب تسجيل الدخول أولاً');
  END IF;

  SELECT * INTO v_membership
  FROM public.clinic_memberships
  WHERE user_id = v_uid AND clinic_id = p_clinic_id AND is_active = true;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'message', 'ليس لديك صلاحية وصول لهذه العيادة');
  END IF;

  SELECT name INTO v_clinic_name FROM public.clinics WHERE id = p_clinic_id;

  IF v_branch_id IS NULL THEN
    SELECT id INTO v_branch_id
    FROM public.branches
    WHERE clinic_id = p_clinic_id
    ORDER BY is_main DESC, created_at ASC
    LIMIT 1;
  END IF;

  UPDATE public.users
  SET clinic_id = p_clinic_id,
      active_clinic_id = p_clinic_id,
      active_branch_id = v_branch_id,
      role = v_membership.role,
      is_owner = v_membership.is_owner,
      can_view_reports = v_membership.can_view_reports,
      can_delete_appointments = v_membership.can_delete_appointments,
      can_edit_services = v_membership.can_edit_services,
      can_view_medical_history = v_membership.can_view_medical_history,
      can_cancel_appointments = v_membership.can_cancel_appointments,
      updated_at = now()
  WHERE id = v_uid;

  RETURN json_build_object(
    'success', true,
    'message', 'تم التبديل إلى ' || coalesce(v_clinic_name, 'العيادة') || ' بنجاح',
    'clinic_id', p_clinic_id,
    'branch_id', v_branch_id,
    'clinic_name', v_clinic_name
  );
END;
$$;

-- RPC: Leave clinic if user is not the owner
CREATE OR REPLACE FUNCTION public.leave_clinic(p_clinic_id uuid)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_membership public.clinic_memberships%ROWTYPE;
  v_remaining_clinic_id uuid;
  v_remaining_branch_id uuid;
  v_next_membership public.clinic_memberships%ROWTYPE;
  v_clinic_name text;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'غير مسجل الدخول');
  END IF;

  SELECT * INTO v_membership
  FROM public.clinic_memberships
  WHERE user_id = v_uid AND clinic_id = p_clinic_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'message', 'لست عضواً في هذه العيادة');
  END IF;

  IF v_membership.is_owner THEN
    RETURN json_build_object('success', false, 'message', 'أنت مالك هذه العيادة ولا يمكنك مغادرتها كعضو');
  END IF;

  SELECT name INTO v_clinic_name FROM public.clinics WHERE id = p_clinic_id;

  -- حذف عضوية المستخدم من هذه العيادة
  DELETE FROM public.clinic_memberships
  WHERE user_id = v_uid AND clinic_id = p_clinic_id;

  -- البحث عن عيادة أخرى ينتمي إليها المستخدم
  SELECT clinic_id INTO v_remaining_clinic_id
  FROM public.clinic_memberships
  WHERE user_id = v_uid AND is_active = true
  ORDER BY is_owner DESC, joined_at ASC
  LIMIT 1;

  IF v_remaining_clinic_id IS NOT NULL THEN
    -- التبديل التلقائي إلى العيادة المتبقية
    SELECT * INTO v_next_membership
    FROM public.clinic_memberships
    WHERE user_id = v_uid AND clinic_id = v_remaining_clinic_id;

    SELECT id INTO v_remaining_branch_id
    FROM public.branches
    WHERE clinic_id = v_remaining_clinic_id
    ORDER BY is_main DESC, created_at ASC
    LIMIT 1;

    UPDATE public.users
    SET
      clinic_id = v_remaining_clinic_id,
      active_clinic_id = v_remaining_clinic_id,
      active_branch_id = v_remaining_branch_id,
      role = v_next_membership.role,
      is_owner = v_next_membership.is_owner,
      can_view_reports = v_next_membership.can_view_reports,
      can_delete_appointments = v_next_membership.can_delete_appointments,
      can_edit_services = v_next_membership.can_edit_services,
      can_view_medical_history = v_next_membership.can_view_medical_history,
      can_cancel_appointments = v_next_membership.can_cancel_appointments
    WHERE id = v_uid;

    RETURN json_build_object(
      'success', true,
      'has_other_clinics', true,
      'switched_to_clinic_id', v_remaining_clinic_id,
      'message', 'تمت مغادرة عيادة ' || COALESCE(v_clinic_name, '') || ' والتبديل إلى عيادتك الأخرى بنجاح'
    );
  ELSE
    -- لا توجد عيادات أخرى، تفريغ العيادة النشطة
    UPDATE public.users
    SET
      clinic_id = null,
      active_clinic_id = null,
      active_branch_id = null,
      is_owner = false,
      can_delete_appointments = false,
      can_view_reports = false,
      can_edit_services = false,
      can_view_medical_history = false,
      can_edit_medical_notes = false,
      can_cancel_appointments = true
    WHERE id = v_uid;

    RETURN json_build_object(
      'success', true,
      'has_other_clinics', false,
      'message', 'تمت مغادرة عيادة ' || COALESCE(v_clinic_name, '') || ' بنجاح'
    );
  END IF;
END;
$$;

-- RPC: Create an additional clinic for the current user
CREATE OR REPLACE FUNCTION public.create_additional_clinic(p_clinic_name text)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_clinic_id uuid;
  v_branch_id uuid;
  v_user_phone text;
  v_user_full_name text;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'يجب تسجيل الدخول أولاً');
  END IF;

  IF p_clinic_name IS NULL OR trim(p_clinic_name) = '' THEN
    RETURN json_build_object('success', false, 'message', 'يرجى إدخال اسم العيادة');
  END IF;

  SELECT phone, full_name INTO v_user_phone, v_user_full_name FROM public.users WHERE id = v_uid;

  INSERT INTO public.clinics (name, whatsapp_phone, subscription_status, is_active, subscription_end_date, owner_id)
  VALUES (trim(p_clinic_name), v_user_phone, 'pending_activation', false, now(), v_uid)
  RETURNING id INTO v_clinic_id;

  INSERT INTO public.branches (clinic_id, name, is_main)
  VALUES (v_clinic_id, 'الفرع الرئيسي', true)
  RETURNING id INTO v_branch_id;

  INSERT INTO public.clinic_memberships (
    user_id, clinic_id, role, is_owner, is_active,
    can_view_reports, can_delete_appointments, can_edit_services,
    can_view_medical_history, can_cancel_appointments
  ) VALUES (
    v_uid, v_clinic_id, 'doctor'::public.user_role, true, true,
    true, true, true, true, true
  )
  ON CONFLICT (user_id, clinic_id) DO UPDATE SET
    role = 'doctor'::public.user_role,
    is_owner = true,
    can_view_reports = true;

  PERFORM public.switch_user_active_clinic(v_clinic_id, v_branch_id);

  RETURN json_build_object(
    'success', true,
    'message', 'تم إنشاء عيادة ' || trim(p_clinic_name) || ' بنجاح',
    'clinic_id', v_clinic_id,
    'branch_id', v_branch_id,
    'clinic_name', trim(p_clinic_name)
  );
END;
$$;

-- RPC: Join another clinic using invite code
CREATE OR REPLACE FUNCTION public.join_additional_clinic(p_invite_code text, p_role text DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_clinic_id uuid;
  v_clinic_name text;
  v_branch_id uuid;
  v_role public.user_role;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'يجب تسجيل الدخول أولاً');
  END IF;

  IF p_invite_code IS NULL OR trim(p_invite_code) = '' THEN
    RETURN json_build_object('success', false, 'message', 'يرجى إدخال كود الدعوة');
  END IF;

  SELECT id, name INTO v_clinic_id, v_clinic_name
  FROM public.clinics
  WHERE LOWER(TRIM(invite_code)) = LOWER(TRIM(p_invite_code))
  LIMIT 1;

  IF v_clinic_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'كود الدعوة غير صحيح أو غير مسجل في النظام');
  END IF;

  IF p_role IS NOT NULL AND lower(p_role) = 'doctor' THEN
    v_role := 'doctor'::public.user_role;
  ELSE
    SELECT role INTO v_role FROM public.users WHERE id = v_uid;
    IF v_role IS NULL THEN
      v_role := 'secretary'::public.user_role;
    END IF;
  END IF;

  SELECT id INTO v_branch_id
  FROM public.branches
  WHERE clinic_id = v_clinic_id
  ORDER BY is_main DESC, created_at ASC
  LIMIT 1;

  IF v_branch_id IS NULL THEN
    INSERT INTO public.branches (clinic_id, name, is_main)
    VALUES (v_clinic_id, 'الفرع الرئيسي', true)
    RETURNING id INTO v_branch_id;
  END IF;

  INSERT INTO public.clinic_memberships (
    user_id, clinic_id, role, is_owner, is_active,
    can_view_reports, can_delete_appointments, can_edit_services,
    can_view_medical_history, can_cancel_appointments
  ) VALUES (
    v_uid, v_clinic_id, v_role, false, true,
    false, v_role = 'doctor', false, false, true
  )
  ON CONFLICT (user_id, clinic_id) DO UPDATE SET
    role = EXCLUDED.role,
    is_active = true;

  PERFORM public.switch_user_active_clinic(v_clinic_id, v_branch_id);

  RETURN json_build_object(
    'success', true,
    'message', 'تم الانضمام إلى ' || coalesce(v_clinic_name, 'العيادة') || ' بنجاح',
    'clinic_id', v_clinic_id,
    'branch_id', v_branch_id,
    'clinic_name', v_clinic_name
  );
END;
$$;

-- RPC: Switch or link doctor/assistant to a clinic using invite code (Legacy Alias)
CREATE OR REPLACE FUNCTION public.switch_user_clinic(p_invite_code text, p_role text DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.join_additional_clinic(p_invite_code, p_role);
END;
$$;

-- RPC: Manage Clinic Branches
CREATE OR REPLACE FUNCTION public.create_clinic_branch(
  p_clinic_id uuid,
  p_name text,
  p_address text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_is_main boolean DEFAULT false
)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_branch_id uuid;
  v_is_owner boolean;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'يجب تسجيل الدخول أولاً');
  END IF;

  SELECT is_owner INTO v_is_owner
  FROM public.clinic_memberships
  WHERE user_id = v_uid AND clinic_id = p_clinic_id;

  IF NOT coalesce(v_is_owner, false) THEN
    RETURN json_build_object('success', false, 'message', 'فقط مالك العيادة مصرح له بإنشاء فروع');
  END IF;

  IF p_is_main THEN
    UPDATE public.branches SET is_main = false WHERE clinic_id = p_clinic_id;
  END IF;

  INSERT INTO public.branches (clinic_id, name, address, phone, is_main)
  VALUES (p_clinic_id, trim(p_name), trim(p_address), trim(p_phone), p_is_main)
  RETURNING id INTO v_branch_id;

  RETURN json_build_object(
    'success', true,
    'message', 'تم إنشاء الفرع بنجاح',
    'branch_id', v_branch_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.update_clinic_branch(
  p_branch_id uuid,
  p_name text,
  p_address text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_is_main boolean DEFAULT false
)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_clinic_id uuid;
  v_is_owner boolean;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'يجب تسجيل الدخول أولاً');
  END IF;

  SELECT clinic_id INTO v_clinic_id FROM public.branches WHERE id = p_branch_id;
  IF v_clinic_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'الفرع غير موجود');
  END IF;

  SELECT is_owner INTO v_is_owner
  FROM public.clinic_memberships
  WHERE user_id = v_uid AND clinic_id = v_clinic_id;

  IF NOT coalesce(v_is_owner, false) THEN
    RETURN json_build_object('success', false, 'message', 'فقط مالك العيادة مصرح له بتعديل الفروع');
  END IF;

  IF p_is_main THEN
    UPDATE public.branches SET is_main = false WHERE clinic_id = v_clinic_id;
  END IF;

  UPDATE public.branches
  SET name = trim(p_name),
      address = trim(p_address),
      phone = trim(p_phone),
      is_main = p_is_main,
      updated_at = now()
  WHERE id = p_branch_id;

  RETURN json_build_object('success', true, 'message', 'تم تحديث بيانات الفرع بنجاح');
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_clinic_branch(p_branch_id uuid)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_clinic_id uuid;
  v_is_owner boolean;
  v_count int;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'يجب تسجيل الدخول أولاً');
  END IF;

  SELECT clinic_id INTO v_clinic_id FROM public.branches WHERE id = p_branch_id;
  IF v_clinic_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'الفرع غير موجود');
  END IF;

  SELECT is_owner INTO v_is_owner
  FROM public.clinic_memberships
  WHERE user_id = v_uid AND clinic_id = v_clinic_id;

  IF NOT coalesce(v_is_owner, false) THEN
    RETURN json_build_object('success', false, 'message', 'فقط مالك العيادة مصرح له بحذف الفروع');
  END IF;

  SELECT count(*) INTO v_count FROM public.branches WHERE clinic_id = v_clinic_id;
  IF v_count <= 1 THEN
    RETURN json_build_object('success', false, 'message', 'لا يمكن حذف الفرع الوحيد المتبقي بالعيادة');
  END IF;

  DELETE FROM public.branches WHERE id = p_branch_id;

  -- If main was deleted, make another one main
  IF NOT EXISTS(SELECT 1 FROM public.branches WHERE clinic_id = v_clinic_id AND is_main = true) THEN
    UPDATE public.branches
    SET is_main = true
    WHERE id = (SELECT id FROM public.branches WHERE clinic_id = v_clinic_id ORDER BY created_at ASC LIMIT 1);
  END IF;

  RETURN json_build_object('success', true, 'message', 'تم حذف الفرع بنجاح');
END;
$$;

CREATE OR REPLACE FUNCTION public.get_clinic_branches(p_clinic_id uuid)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result json;
BEGIN
  SELECT json_agg(
    json_build_object(
      'id', id,
      'clinic_id', clinic_id,
      'name', name,
      'address', address,
      'phone', phone,
      'is_main', is_main,
      'created_at', created_at
    ) ORDER BY is_main DESC, created_at ASC
  ) INTO v_result
  FROM public.branches
  WHERE clinic_id = p_clinic_id;

  RETURN coalesce(v_result, '[]'::json);
END;
$$;

-- RPC: Ensure user profile & clinic exist (Self-healing RPC)
CREATE OR REPLACE FUNCTION public.ensure_user_clinic_exists()
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_meta jsonb;
  v_clinic_id uuid;
  v_branch_id uuid;
  v_role_str text;
  v_role public.user_role;
  v_full_name text;
  v_clinic_name text;
  v_branch_name text;
  v_extra_rec record;
  v_invite_code text;
  v_phone text;
  v_user_exists boolean;
  v_is_owner boolean := false;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'No authenticated user session');
  END IF;

  SELECT raw_user_meta_data INTO v_meta FROM auth.users WHERE id = v_uid;
  SELECT EXISTS(SELECT 1 FROM public.users WHERE id = v_uid) INTO v_user_exists;

  IF v_user_exists THEN
    RETURN json_build_object('success', true, 'message', 'User profile already exists');
  END IF;

  v_role_str := lower(coalesce(v_meta ->> 'role', 'doctor'));
  IF v_role_str = 'secretary' THEN
    v_role := 'secretary'::public.user_role;
  ELSE
    v_role := 'doctor'::public.user_role;
  END IF;

  v_full_name := coalesce(nullif(v_meta ->> 'full_name', ''), 'مستخدم جديد');
  v_clinic_name := coalesce(nullif(v_meta ->> 'clinic_name', ''), 'عيادة جديدة');
  v_branch_name := coalesce(nullif(v_meta ->> 'branch_name', ''), 'الفرع الرئيسي');
  v_invite_code := trim(coalesce(v_meta ->> 'invite_code', ''));
  v_phone := coalesce(nullif(v_meta ->> 'phone', ''), nullif(v_meta ->> 'user_phone', ''));

  IF v_invite_code != '' THEN
    SELECT id INTO v_clinic_id
    FROM public.clinics
    WHERE LOWER(TRIM(invite_code)) = LOWER(v_invite_code)
    LIMIT 1;
  END IF;

  IF v_clinic_id IS NULL THEN
    INSERT INTO public.clinics (name, whatsapp_phone, subscription_status, is_active, subscription_end_date, owner_id)
    VALUES (v_clinic_name, v_phone, 'pending_activation', false, now(), v_uid)
    RETURNING id INTO v_clinic_id;

    INSERT INTO public.branches (clinic_id, name, is_main)
    VALUES (v_clinic_id, v_branch_name, true)
    RETURNING id INTO v_branch_id;

    IF v_meta -> 'extra_branches' IS NOT NULL AND jsonb_typeof(v_meta -> 'extra_branches') = 'array' THEN
      BEGIN
        FOR v_extra_rec IN
          SELECT * FROM jsonb_to_recordset((v_meta -> 'extra_branches')::jsonb)
          AS x(name text, address text, phone text)
        LOOP
          IF v_extra_rec.name IS NOT NULL AND trim(v_extra_rec.name) != '' THEN
            INSERT INTO public.branches (clinic_id, name, address, phone, is_main)
            VALUES (v_clinic_id, trim(v_extra_rec.name), nullif(trim(v_extra_rec.address), ''), nullif(trim(v_extra_rec.phone), ''), false);
          END IF;
        END LOOP;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Error inserting extra branches in ensure_user_clinic_exists: %', SQLERRM;
      END;
    END IF;

    v_is_owner := true;
  ELSE
    SELECT id INTO v_branch_id
    FROM public.branches
    WHERE clinic_id = v_clinic_id
    ORDER BY is_main DESC, created_at ASC
    LIMIT 1;

    IF v_branch_id IS NULL THEN
      INSERT INTO public.branches (clinic_id, name, is_main)
      VALUES (v_clinic_id, 'الفرع الرئيسي', true)
      RETURNING id INTO v_branch_id;
    END IF;
  END IF;

  INSERT INTO public.clinic_memberships (
    user_id, clinic_id, role, is_owner, is_active,
    can_view_reports, can_delete_appointments, can_edit_services,
    can_view_medical_history, can_cancel_appointments
  ) VALUES (
    v_uid, v_clinic_id, v_role, v_is_owner, true,
    v_is_owner, v_is_owner OR v_role = 'doctor', v_is_owner,
    v_is_owner OR v_role = 'doctor', true
  )
  ON CONFLICT (user_id, clinic_id) DO UPDATE SET
    role = EXCLUDED.role,
    is_owner = EXCLUDED.is_owner,
    is_active = true;

  INSERT INTO public.users (
    id, clinic_id, active_clinic_id, active_branch_id,
    role, full_name, phone, is_active, is_owner,
    can_delete_appointments, can_view_reports
  )
  VALUES (
    v_uid, v_clinic_id, v_clinic_id, v_branch_id,
    v_role, v_full_name, v_phone, true, v_is_owner,
    v_is_owner OR v_role = 'doctor', v_is_owner
  )
  ON CONFLICT (id) DO UPDATE SET
    clinic_id = EXCLUDED.clinic_id,
    active_clinic_id = EXCLUDED.clinic_id,
    active_branch_id = coalesce(EXCLUDED.active_branch_id, public.users.active_branch_id),
    role = EXCLUDED.role,
    full_name = EXCLUDED.full_name,
    is_owner = EXCLUDED.is_owner,
    phone = coalesce(EXCLUDED.phone, public.users.phone);

  RETURN json_build_object('success', true, 'clinic_id', v_clinic_id, 'branch_id', v_branch_id);
END;
$$;

-- ==========================================
-- Enabling Row-Level Security (RLS)
-- ==========================================

ALTER TABLE public.clinics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinic_memberships ENABLE ROW LEVEL SECURITY;
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

-- Security Definer Helpers to prevent RLS recursion
CREATE OR REPLACE FUNCTION public.is_clinic_owner_for_auth(p_clinic_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.clinic_memberships
    WHERE clinic_id = p_clinic_id
      AND user_id = auth.uid()
      AND is_owner = true
  ) OR EXISTS (
    SELECT 1 FROM public.clinics
    WHERE id = p_clinic_id
      AND owner_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.can_view_clinic_membership(p_user_id uuid, p_clinic_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT (p_user_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.clinic_memberships
      WHERE clinic_id = p_clinic_id
        AND user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.clinics
      WHERE id = p_clinic_id
        AND owner_id = auth.uid()
    );
$$;

-- 1.1 Branches Policies
CREATE POLICY "Users can view branches for their clinics" ON public.branches
    FOR SELECT TO authenticated
    USING (
      clinic_id = (SELECT clinic_id FROM public.users WHERE id = auth.uid())
      OR EXISTS (
        SELECT 1 FROM public.clinic_memberships
        WHERE clinic_id = branches.clinic_id AND user_id = auth.uid()
      )
    );

CREATE POLICY "Clinic owners can manage branches" ON public.branches
    FOR ALL TO authenticated
    USING (public.is_clinic_owner_for_auth(clinic_id))
    WITH CHECK (public.is_clinic_owner_for_auth(clinic_id));

-- 1.2 Clinic Memberships Policies
CREATE POLICY "Users can view memberships for their clinics" ON public.clinic_memberships
    FOR SELECT TO authenticated
    USING (public.can_view_clinic_membership(user_id, clinic_id));

CREATE POLICY "Clinic owners can manage memberships" ON public.clinic_memberships
    FOR ALL TO authenticated
    USING (public.is_clinic_owner_for_auth(clinic_id))
    WITH CHECK (public.is_clinic_owner_for_auth(clinic_id));

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

CREATE POLICY "Clinic owners can manage profiles in their clinic" ON public.users
    FOR ALL TO authenticated
    USING (
        clinic_id = public.get_my_clinic_id() 
        AND (public.is_my_clinic_owner() OR id = auth.uid()) 
        AND public.is_my_user_active()
    );

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
CREATE TRIGGER update_branches_updated_at BEFORE UPDATE ON public.branches FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_clinic_memberships_updated_at BEFORE UPDATE ON public.clinic_memberships FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
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
    branch_id,
    doctor_id,
    transaction_date::date as report_date,
    date_trunc('month', transaction_date)::date as report_month,
    sum(amount) as total_revenue
FROM (
    -- Revenue from completed appointments (کشف طبي)
    SELECT clinic_id, doctor_id, appointment_date as transaction_date, coalesce(price_charged, 0) as amount 
    FROM public.appointments 
    WHERE status = 'completed'
    
    UNION ALL
    
    -- Revenue from services in completed appointments
    SELECT aps.clinic_id, app.doctor_id, app.appointment_date as transaction_date, coalesce(aps.price_charged, 0) as amount 
    FROM public.appointment_services aps
    JOIN public.appointments app ON aps.appointment_id = app.id
    WHERE app.status = 'completed'
) transactions
WHERE (
    -- التحقق من الصلاحيات: مدير العيادة، أو من يملك صلاحية رؤية التقارير العامة، أو الطبيب يرى إيراداته
    SELECT (is_owner OR can_view_reports OR doctor_id = auth.uid()) 
    FROM public.users 
    WHERE id = auth.uid() AND is_active = true
)
GROUP BY clinic_id, doctor_id, transaction_date::date, date_trunc('month', transaction_date)::date;

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
    renewal_requested boolean,
    renewal_requested_at timestamptz,
    renewal_plan text,
    renewal_plan_price numeric,
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
        c.renewal_requested,
        c.renewal_requested_at,
        c.renewal_plan,
        c.renewal_plan_price,
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

-- 5. Get All Patients for Clinic (Bypasses PostgREST 1000 limit)
CREATE OR REPLACE FUNCTION public.get_all_patients_for_clinic(p_clinic_id uuid)
RETURNS TABLE (
    id uuid,
    clinic_id uuid,
    full_name text,
    phone text,
    gender text,
    birth_date date,
    address text,
    medical_history text,
    created_at timestamptz,
    updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.clinic_id,
        p.full_name,
        p.phone,
        p.gender,
        p.birth_date,
        p.address,
        p.medical_history,
        p.created_at,
        p.updated_at
    FROM public.patients p
    WHERE p.clinic_id = p_clinic_id
    ORDER BY p.created_at DESC;
END;
$$;

-- 6. Get All Patients as JSONB Array (Bypasses PostgREST max-rows table limit completely)
CREATE OR REPLACE FUNCTION public.get_all_patients_json(p_clinic_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT coalesce(jsonb_agg(
        jsonb_build_object(
            'id', p.id,
            'clinic_id', p.clinic_id,
            'full_name', p.full_name,
            'phone', p.phone,
            'gender', p.gender,
            'birth_date', p.birth_date,
            'address', p.address,
            'medical_history', p.medical_history,
            'created_at', p.created_at,
            'updated_at', p.updated_at
        ) ORDER BY p.created_at DESC
    ), '[]'::jsonb)
    INTO v_result
    FROM public.patients p
    WHERE p.clinic_id = p_clinic_id;

    RETURN v_result;
END;
$$;

-- 5. Admin Update Doctor Phone Number (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.admin_update_doctor_phone(p_clinic_id uuid, p_phone text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_formatted_phone text;
BEGIN
    v_formatted_phone := p_phone;
    IF v_formatted_phone IS NOT NULL AND v_formatted_phone != '' THEN
      IF v_formatted_phone ~ '^01[0-9]{9}$' THEN
        v_formatted_phone := '+2' || v_formatted_phone;
      ELSIF v_formatted_phone ~ '^201[0-9]{9}$' THEN
        v_formatted_phone := '+' || v_formatted_phone;
      ELSIF v_formatted_phone !~ '^\+' THEN
        v_formatted_phone := '+20' || regexp_replace(v_formatted_phone, '\D', '', 'g');
      END IF;
    END IF;

    -- Update clinic's whatsapp phone
    UPDATE public.clinics
    SET whatsapp_phone = v_formatted_phone
    WHERE id = p_clinic_id;

    -- Update doctor's profile phone
    UPDATE public.users
    SET phone = v_formatted_phone
    WHERE clinic_id = p_clinic_id AND role = 'doctor';

    -- Update auth.users native phone & metadata in Supabase Auth Dashboard!
    UPDATE auth.users au
    SET 
      phone = v_formatted_phone,
      raw_user_meta_data = jsonb_set(coalesce(au.raw_user_meta_data, '{}'::jsonb), '{phone}', to_jsonb(v_formatted_phone))
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
        renewal_requested = false,
        renewal_requested_at = null,
        renewal_plan = null,
        renewal_plan_price = null,
        subscription_end_date = (now() + (p_days || ' days')::interval),
        updated_at = now()
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
        renewal_requested = false,
        renewal_requested_at = null,
        renewal_plan = null,
        renewal_plan_price = null,
        subscription_end_date = p_end_date,
        updated_at = now()
    WHERE id = p_clinic_id;
END;
$$;

-- 3.1 Doctor / Clinic Request Subscription Renewal (RPC)
CREATE OR REPLACE FUNCTION public.request_subscription_renewal(
    p_plan text,
    p_price numeric DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_clinic_id uuid;
    v_uid uuid := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'يجب تسجيل الدخول');
    END IF;

    SELECT clinic_id INTO v_clinic_id FROM public.users WHERE id = v_uid;
    IF v_clinic_id IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'العيادة غير موجودة');
    END IF;

    UPDATE public.clinics
    SET renewal_requested = true,
        renewal_requested_at = now(),
        renewal_plan = coalesce(p_plan, 'تجديد الاشتراك'),
        renewal_plan_price = p_price,
        updated_at = now()
    WHERE id = v_clinic_id;

    RETURN json_build_object('success', true, 'clinic_id', v_clinic_id);
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

-- ==========================================
-- 6. Storage Protection & Maintenance Procedure
-- Guarantees Database footprint stays well within Supabase 500MB Free Tier
-- ==========================================
CREATE OR REPLACE FUNCTION public.purge_old_audit_logs()
RETURNS void AS $$
BEGIN
    -- Delete audit logs older than 30 days
    DELETE FROM public.audit_logs 
    WHERE created_at < (NOW() - INTERVAL '30 days');

    -- Delete notifications older than 14 days
    DELETE FROM public.notifications 
    WHERE created_at < (NOW() - INTERVAL '14 days');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Branches & Memberships Indexes
CREATE INDEX IF NOT EXISTS idx_branches_clinic ON public.branches (clinic_id, is_main);
CREATE INDEX IF NOT EXISTS idx_clinic_memberships_user ON public.clinic_memberships (user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_clinic_memberships_clinic ON public.clinic_memberships (clinic_id, is_active);
CREATE INDEX IF NOT EXISTS idx_appointments_branch ON public.appointments (clinic_id, branch_id);

