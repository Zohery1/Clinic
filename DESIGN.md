---
name: Clinical Precision — Eyadaty Design System
colors:
  primary: '#1A73E8'
  primary-light: '#E8F0FE'
  on-primary: '#FFFFFF'
  background: '#F8F9FB'
  surface: '#FFFFFF'
  surface-dim: '#F1F5F9'
  border: '#F1F5F9'
  text-primary: '#1E293B'
  text-secondary: '#64748B'
  text-hint: '#9CA3AF'
  status-success: '#059669'
  status-warning: '#D97706'
  status-error: '#DC2626'
  status-completed: '#7C3AED'
  dark-background: '#0F172A'
  dark-surface: '#1E293B'
  dark-primary: '#3B82F6'
  dark-border: '#334155'
typography:
  headline-xl:
    fontFamily: Cairo
    fontSize: 26px
    fontWeight: '800'
    lineHeight: 1.3
  headline-lg:
    fontFamily: Cairo
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 1.3
  title-lg:
    fontFamily: Cairo
    fontSize: 18px
    fontWeight: '700'
  title-md:
    fontFamily: Cairo
    fontSize: 16px
    fontWeight: '600'
  body-lg:
    fontFamily: Cairo
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 1.6
  body-md:
    fontFamily: Cairo
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 1.5
  body-sm:
    fontFamily: Cairo
    fontSize: 12px
    fontWeight: '500'
  label-mono:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-mono-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 4px
  DEFAULT: 10px
  md: 12px
  lg: 14px
  xl: 16px
  full: 9999px
spacing:
  touch-target-min: 44px
  card-padding: 16px
  dialog-radius: 16px
---

# Design System: Eyadaty (عيادتي) — Smart Clinic Management SaaS

## 1. Visual Theme & Atmosphere
نظام تصميم طبي سحابي هادئ وعصري (Clean Medical SaaS) مبني على مبادئ الثقة الطبية، الوضوح، والراحة البصرية لتقليل العبء المعرفي على الأطباء وفرق الاستقبال والسكرتارية. يعتمد النظام على تباين لوني مدروس، ومساحات تنفس مريحة، وزوايا ناعمة وبسيطة.

---

## 2. Color Palette & Roles (لوحة الألوان المعتمدة)

### ☀️ Light Theme (الوضع الفاتح - الأساسي):
- **Primary Blue** (`#1A73E8`) — اللون الرئيسي، الأزرار الأساسية، التحديد، والشعارات.
- **Primary Light** (`#E8F0FE`) — خلفيات التمييز، شارات الحالة النشطة، وتأثيرات الـ Hover.
- **Canvas / Background** (`#F8F9FB`) — خلفية الشاشات العامة، مريحة للعين وتمنح إحساساً بالنظافة والاتساع.
- **Surface / Cards** (`#FFFFFF`) — خلفية البطاقات، النوافذ المنبثقة، والأسطح المرتفعة.
- **Surface Dim / Inputs** (`#F1F5F9`) — خلفية حقول الإدخال والألواح الجانبية المنسدلة.
- **Border** (`#F1F5F9`) — خطوط الفواصل الدقيقة وحدود البطاقات الهادئة.
- **Text Primary** (`#1E293B` - Slate 800) — العناوين الرئيسية والنصوص الهامة (بديل أسود ناعم ومريح).
- **Text Secondary** (`#64748B` - Slate 500) — النصوص التوضيحية، البيانات الوصفية، والأوصاف الفرعية.
- **Text Hint** (`#9CA3AF`) — النصوص التلميحية داخل الحقول.

### 🌙 Dark Theme (الوضع الداكن):
- **Scaffold Background** (`#0F172A` - Slate 900) — الخلفية العامة الداكنة.
- **Card & Surface** (`#1E293B` - Slate 800) — أسطح البطاقات والحقول والألواح.
- **Primary Accent** (`#3B82F6` - Blue 500) — لون التمييز والأزرار في الوضع المظلم.
- **Borders & Dividers** (`#334155` - Slate 700) — فواصل الوضع الداكن.

### 🚦 Status Colors (ألوان الحالات والمواعيد):
- **Status Success** (`#059669` - Emerald) — الكشوفات المكتملة، الدفع المؤكد، الحسابات النشطة.
- **Status Warning** (`#D97706` - Amber) — في الانتظار (Queue)، اشتراك قارب على الانتهاء.
- **Status Error** (`#DC2626` - Red) — الإلغاءات، الحسابات المحظورة، الحذف، أخطاء الإدخال.
- **Status Completed / Special** (`#7C3AED` - Purple) — الزيارات المنتهية والملاحظات الطبية المؤرشفة.

---

## 3. Typography Rules (قواعد التايبوجرافي)

- **الخط الأساسي للنظام**: **Cairo** (Google Fonts).
  - خط عربي عصري ممتاز القراءة على مختلف الشاشات، مدعوم بأوزان متعددة:
  - **ExtraBold (800)**: للعناوين الرئيسية للواجهات والصفحات الكبرى.
  - **Bold (700)**: لعناوين البطاقات، النوافذ المنبثقة، ونصوص الأزرار الهامة.
  - **SemiBold (600)**: للعناوين الفرعية وحقول الإدخال.
  - **Regular (400) & Medium (500)**: لنصوص الجداول والملاحظات الطبية وبيانات المرضى.
- **الخط الرقمي والمونو**: **JetBrains Mono**.
  - مخصص حصرياً للمبالغ المالية (LE / EGP)، أكواد الحجز والدعوات (Invite Codes)، الطوابع الزمنية، وأرقام الهواتف.

---

## 4. Component Stylings (أنماط المكونات البرمجية)

- **Buttons (الأزرار)**:
  - حواف دائرية `10px` مع ارتفاع مريح (`minimumSize: 48px`).
  - نصوص واضحة بوزن `Bold (700)`.
  - تأثيرات ضغط خفيفة وبدون توهجات نيون مبالغ فيها.
- **Cards (البطاقات)**:
  - حواف دائرية `12px` مع ظل ناعم جداً (`boxShadow: color.withOpacity(0.02), blurRadius: 20, offset: (0,4)`).
  - خيار البطاقات المسطحة (Flat Cards) للجداول ولوحات المواعيد.
- **Inputs (حقول الإدخال)**:
  - خلفية ناعمة (`#F1F5F9`) مع حواف دائرية `10px`.
  - اختفاء الحدود في الحالة العادية، وظهور حدود زرقاء ناعمة `1.5px` عند التركيز (Focus).
- **Dialogs & Sheets (النوافذ المنبثقة)**:
  - حواف `16px`، خلفية بيضاء نقية، وأزرار إجراءات واضحة في الأسفل.

---

## 5. Layout & Interaction Principles (مبادئ التخطيط والتفاعل)

- **دعم اللغة العربية و RTL بالكامل**: الواجهة مصممة أصلاً لتدفق القراءة من اليمين لليسار مع مراعاة محاذاة الأيقونات والأزرار.
- **التصميم المتجاوب (Responsive Design)**: تجربة مستخدم موحدة على الويب (Desktop / Tablet) وتطبيقات الجوال (Mobile) مع حد أدنى لمساحة اللمس `44px`.
- **لوحة الانتظار التفاعلية (Live Queue Board)**: تحديث فوري لحالات المرضى (في الانتظار، داخل الكشف، مكتمل، ملغي) بألوان الحالات المعتمدة.

---

## 6. Anti-Patterns (الممارسات المحظورة)
- ❌ استخدام ألوان الأسود الصريح (`#000000`) — استخدم دائماً Slate الداكن (`#1E293B`).
- ❌ استخدام خطوط غير معتمدة أو عشوائية خارج **Cairo** و **JetBrains Mono**.
- ❌ استخدام تدرجات فاقعة أو ظلال حادة تشتت تركيز الكادر الطبي.
- ❌ عناصر لمس أصغر من `44px` في شاشات الجوال أو التابلت.
