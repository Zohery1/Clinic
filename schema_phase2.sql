-- =========================================================================
-- Eyadaty SaaS - Phase 2 Database Schema & Migrations
-- Feature Scope: Multi-Branch, Multi-Doctor, & Specialty Clinical Workspaces
-- (Pediatrics, Ophthalmology, Internal Medicine, Pulmonology, Veterinary)
-- =========================================================================

-- 1. جدول الفروع (Branches)
CREATE TABLE IF NOT EXISTS public.branches (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    name text NOT NULL,
    phone text,
    address text,
    is_active boolean NOT NULL DEFAULT true,
    whatsapp_phone text,
    whatsapp_instance_name text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2. جدول ربط الكوادر بالفروع (User Branches Junction)
CREATE TABLE IF NOT EXISTS public.user_branches (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    is_primary boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(user_id, branch_id)
);

-- 3. تحديث جدول المواعيد (Appointments Update)
ALTER TABLE public.appointments 
ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES public.branches(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS doctor_id uuid REFERENCES public.users(id) ON DELETE SET NULL;

-- 4. جدول السجلات والزيارات الطبية التخصصية (Core Clinical Visits)
CREATE TABLE IF NOT EXISTS public.clinical_visits (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    branch_id uuid REFERENCES public.branches(id) ON DELETE SET NULL,
    appointment_id uuid UNIQUE REFERENCES public.appointments(id) ON DELETE CASCADE,
    patient_id uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    doctor_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    specialty text NOT NULL CHECK (specialty IN ('pediatrics', 'ophthalmology', 'internal_medicine', 'pulmonology', 'veterinary', 'general')) DEFAULT 'general',
    visit_status text NOT NULL DEFAULT 'draft' CHECK (visit_status IN ('draft', 'in_progress', 'completed', 'signed', 'amended')),
    chief_complaint text,
    diagnosis_primary text,
    diagnosis_secondary text,
    treatment_plan text,
    clinical_data jsonb NOT NULL DEFAULT '{}'::jsonb,
    follow_up_date date,
    follow_up_instructions text,
    is_signed boolean NOT NULL DEFAULT false,
    signed_at timestamptz,
    signed_by uuid REFERENCES public.users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 5. جدول طلبات الفحوصات والتحاليل المعملية (Diagnostic & Lab Orders)
CREATE TABLE IF NOT EXISTS public.diagnostic_orders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    visit_id uuid NOT NULL REFERENCES public.clinical_visits(id) ON DELETE CASCADE,
    patient_id uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    test_type text NOT NULL, -- 'lab', 'imaging', 'ophthalmic_oct', 'spirometry'
    test_name text NOT NULL,
    status text NOT NULL DEFAULT 'ordered' CHECK (status IN ('ordered', 'pending', 'received', 'reviewed')),
    results_payload jsonb,
    attachments_urls text[],
    doctor_comments text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 6. جدول سجلات التطعيمات الرقمية (Patient Vaccinations)
CREATE TABLE IF NOT EXISTS public.patient_vaccinations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    patient_id uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    vaccine_name text NOT NULL,
    dose_number int NOT NULL DEFAULT 1,
    administered_date date,
    next_due_date date,
    status text NOT NULL DEFAULT 'due' CHECK (status IN ('given', 'due', 'overdue', 'refused', 'contraindicated')),
    batch_number text,
    administered_by uuid REFERENCES public.users(id),
    notes text,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- 7. جدول الحيوانات الأليفة (خاص بالعيادات البيطرية)
CREATE TABLE IF NOT EXISTS public.veterinary_animals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    owner_patient_id uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    animal_name text NOT NULL,
    species text NOT NULL,
    breed text,
    gender text CHECK (gender IN ('male', 'female', 'neutered_male', 'spayed_female')),
    birth_date date,
    microchip_id text,
    color_marks text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- 8. جدول سجل التدقيق الطبي غير القابل للتعديل (Clinical Audit Logs)
CREATE TABLE IF NOT EXISTS public.clinical_audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    entity_type text NOT NULL, -- 'clinical_visit', 'prescription', 'vitals', 'orders'
    entity_id uuid NOT NULL,
    user_id uuid NOT NULL REFERENCES public.users(id),
    action text NOT NULL, -- 'created', 'updated', 'signed', 'amended'
    change_reason text,
    old_data jsonb,
    new_data jsonb,
    ip_address text,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- 9. سكريبت ترحيل بيانات Phase 1 تلقائياً (Zero-Downtime Migration Helper)
DO $$
DECLARE
    r RECORD;
    default_branch_id uuid;
BEGIN
    FOR r IN SELECT id, name FROM public.clinics LOOP
        -- إنشاء فرع رئيسي افتراضي إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT 1 FROM public.branches WHERE clinic_id = r.id) THEN
            INSERT INTO public.branches (clinic_id, name, is_active)
            VALUES (r.id, 'الفرع الرئيسي', true)
            RETURNING id INTO default_branch_id;

            -- ربط جميع مستخدمي العيادة بالفرع الرئيسي الافتراضي
            INSERT INTO public.user_branches (user_id, branch_id, clinic_id, is_primary)
            SELECT id, default_branch_id, r.id, true
            FROM public.users
            WHERE clinic_id = r.id
            ON CONFLICT DO NOTHING;

            -- ربط جميع المواعيد السابقة بالفرع الرئيسي
            UPDATE public.appointments
            SET branch_id = default_branch_id
            WHERE clinic_id = r.id AND branch_id IS NULL;
        END IF;
    END LOOP;
END $$;
