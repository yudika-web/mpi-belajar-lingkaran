-- Query opsional untuk guru/admin di Supabase SQL Editor.
-- Tidak perlu dijalankan sebagai schema migration.

-- Semua hasil, terbaru dulu
select
  student_name,
  class_name,
  score,
  category,
  created_at
from public.evaluation_results
order by created_at desc;

-- Nilai kelas 9A
select
  student_name,
  score,
  category,
  created_at
from public.evaluation_results
where class_name = '9A'
order by created_at desc;

-- Nilai kelas 9B
select
  student_name,
  score,
  category,
  created_at
from public.evaluation_results
where class_name = '9B'
order by created_at desc;

-- Rekap sederhana per kelas
select
  class_name,
  count(*) as jumlah_attempt,
  round(avg(score), 2) as rata_rata,
  min(score) as nilai_min,
  max(score) as nilai_max
from public.evaluation_results
group by class_name
order by class_name;
