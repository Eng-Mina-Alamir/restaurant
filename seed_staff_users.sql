-- ==============================================================================
-- 👥 SEED USERS & STAFF ACCOUNTS SCRIPT (SUPABASE SQL EDITOR)
-- سكريبت إنشاء حسابات طاقم العمل التجريبية والإنتاجية في Supabase
-- ==============================================================================

-- ℹ️ Note: Users can simply register directly from the app via the Register Screen!
-- Alternatively, this script generates profiles or assigns roles.

-- 1. Example function to set a user's role by email
CREATE OR REPLACE FUNCTION public.set_user_role(target_email TEXT, target_role TEXT)
RETURNS void AS $$
BEGIN
  UPDATE public.profiles
  SET role = target_role, updated_at = NOW()
  WHERE email = target_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. List of standard roles supported in the system:
-- 'customer' : عميل
-- 'waiter'   : نادل / كابتن صالة
-- 'kitchen'  : رئيس المطبخ / شيف
-- 'manager'  : مدير المطعم
-- 'driver'   : مندوب التوصيل
-- 'admin'    : مسؤول النظام
