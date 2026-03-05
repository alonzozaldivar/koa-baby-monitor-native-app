-- ============================================================================
-- KOA BABY MONITOR - SCHEMA DE SUPABASE
-- ============================================================================
-- Este script crea todas las tablas necesarias para la app KOA
-- con Row Level Security habilitado para proteger datos de usuarios

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLA: users (perfil extendido de auth.users)
-- ============================================================================
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS para users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================================================
-- TABLA: face_biometrics
-- ============================================================================
CREATE TABLE public.face_biometrics (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  face_encoding JSONB NOT NULL,
  device_id TEXT,
  registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS para face_biometrics
ALTER TABLE public.face_biometrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own biometrics" ON public.face_biometrics
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own biometrics" ON public.face_biometrics
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own biometrics" ON public.face_biometrics
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own biometrics" ON public.face_biometrics
  FOR DELETE USING (auth.uid() = user_id);

-- Índice para búsqueda rápida
CREATE INDEX idx_face_biometrics_user_id ON public.face_biometrics(user_id);

-- ============================================================================
-- TABLA: baby_profiles
-- ============================================================================
CREATE TABLE public.baby_profiles (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  birthdate DATE NOT NULL,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS para baby_profiles
ALTER TABLE public.baby_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own babies" ON public.baby_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own babies" ON public.baby_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own babies" ON public.baby_profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own babies" ON public.baby_profiles
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_baby_profiles_user_id ON public.baby_profiles(user_id);

-- ============================================================================
-- TABLA: feeding_entries
-- ============================================================================
CREATE TABLE public.feeding_entries (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  baby_id UUID REFERENCES public.baby_profiles(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT CHECK (type IN ('breast', 'bottle', 'solid')) NOT NULL,
  amount TEXT,
  notes TEXT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS para feeding_entries
ALTER TABLE public.feeding_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own feeding entries" ON public.feeding_entries
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own feeding entries" ON public.feeding_entries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own feeding entries" ON public.feeding_entries
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own feeding entries" ON public.feeding_entries
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_feeding_entries_baby_id ON public.feeding_entries(baby_id);
CREATE INDEX idx_feeding_entries_user_id ON public.feeding_entries(user_id);
CREATE INDEX idx_feeding_entries_timestamp ON public.feeding_entries(timestamp DESC);

-- ============================================================================
-- TABLA: medical_appointments
-- ============================================================================
CREATE TABLE public.medical_appointments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  baby_id UUID REFERENCES public.baby_profiles(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  doctor_name TEXT,
  date TIMESTAMP WITH TIME ZONE NOT NULL,
  notes TEXT,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS para medical_appointments
ALTER TABLE public.medical_appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own appointments" ON public.medical_appointments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own appointments" ON public.medical_appointments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own appointments" ON public.medical_appointments
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own appointments" ON public.medical_appointments
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_medical_appointments_baby_id ON public.medical_appointments(baby_id);
CREATE INDEX idx_medical_appointments_date ON public.medical_appointments(date);

-- ============================================================================
-- TABLA: medicines
-- ============================================================================
CREATE TABLE public.medicines (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  baby_id UUID REFERENCES public.baby_profiles(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  dosage TEXT,
  frequency TEXT,
  start_date DATE,
  end_date DATE,
  times JSONB, -- Array de horas ["08:00", "14:00", "20:00"]
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS para medicines
ALTER TABLE public.medicines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own medicines" ON public.medicines
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own medicines" ON public.medicines
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own medicines" ON public.medicines
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own medicines" ON public.medicines
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_medicines_baby_id ON public.medicines(baby_id);

-- ============================================================================
-- TABLA: vaccine_records
-- ============================================================================
CREATE TABLE public.vaccine_records (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  baby_id UUID REFERENCES public.baby_profiles(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  vaccine_id TEXT NOT NULL,
  vaccine_name TEXT NOT NULL,
  applied BOOLEAN DEFAULT FALSE,
  date_applied DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS para vaccine_records
ALTER TABLE public.vaccine_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own vaccine records" ON public.vaccine_records
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own vaccine records" ON public.vaccine_records
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own vaccine records" ON public.vaccine_records
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own vaccine records" ON public.vaccine_records
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_vaccine_records_baby_id ON public.vaccine_records(baby_id);

-- ============================================================================
-- TABLA: sleep_sessions
-- ============================================================================
CREATE TABLE public.sleep_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  baby_id UUID REFERENCES public.baby_profiles(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  duration_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS para sleep_sessions
ALTER TABLE public.sleep_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own sleep sessions" ON public.sleep_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sleep sessions" ON public.sleep_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sleep sessions" ON public.sleep_sessions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own sleep sessions" ON public.sleep_sessions
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_sleep_sessions_baby_id ON public.sleep_sessions(baby_id);
CREATE INDEX idx_sleep_sessions_start_time ON public.sleep_sessions(start_time DESC);

-- ============================================================================
-- TABLA: diary_milestones
-- ============================================================================
CREATE TABLE public.diary_milestones (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  baby_id UUID REFERENCES public.baby_profiles(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  date DATE NOT NULL,
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS para diary_milestones
ALTER TABLE public.diary_milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own milestones" ON public.diary_milestones
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own milestones" ON public.diary_milestones
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own milestones" ON public.diary_milestones
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own milestones" ON public.diary_milestones
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_diary_milestones_baby_id ON public.diary_milestones(baby_id);
CREATE INDEX idx_diary_milestones_date ON public.diary_milestones(date DESC);

-- ============================================================================
-- TABLA: camera_configs
-- ============================================================================
CREATE TABLE public.camera_configs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  host TEXT NOT NULL,
  protocol TEXT CHECK (protocol IN ('rtsp', 'http')) DEFAULT 'rtsp',
  rtsp_port INTEGER DEFAULT 554,
  rtsp_path TEXT DEFAULT '/stream1',
  http_port INTEGER DEFAULT 4747,
  http_path TEXT DEFAULT '/video',
  username TEXT,
  password TEXT, -- Debe encriptarse en cliente antes de guardar
  has_ptz BOOLEAN DEFAULT TRUE,
  has_audio BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS para camera_configs
ALTER TABLE public.camera_configs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cameras" ON public.camera_configs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cameras" ON public.camera_configs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cameras" ON public.camera_configs
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cameras" ON public.camera_configs
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_camera_configs_user_id ON public.camera_configs(user_id);

-- ============================================================================
-- FUNCIONES Y TRIGGERS
-- ============================================================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para users
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger para baby_profiles
CREATE TRIGGER update_baby_profiles_updated_at
  BEFORE UPDATE ON public.baby_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FUNCIÓN: Crear perfil de usuario automáticamente después del registro
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear perfil automáticamente
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- GRANTS (Permisos)
-- ============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
