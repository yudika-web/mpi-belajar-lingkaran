# MPI Ekspedisi Planet Lingkaran — GitHub Pages + Supabase

Paket ini berisi versi MPI yang dapat di-host di **GitHub Pages** dengan backend **Supabase**.

## Arsitektur

- **GitHub Pages**: hosting file HTML/JS/CSS statis.
- **Supabase Auth (Anonymous Sign-In)**: membuat ID unik untuk browser/siswa tanpa email/password.
- **Supabase Postgres + RLS**: menyimpan progres dan hasil evaluasi dengan kebijakan bahwa siswa hanya bisa mengakses datanya sendiri.
- **localStorage**: cache/offline. Saat internet kembali, aplikasi mencoba menyinkronkan data ke Supabase.
- **Tidak ada `service_role` key di browser.**

Struktur folder:

```text
mpi-lingkaran-github-supabase/
├── public/
│   ├── index.html
│   ├── supabase-config.js
│   └── .nojekyll
├── supabase/
│   └── schema.sql
├── .github/
│   └── workflows/
│       └── pages.yml
└── README.md
```

---

# BAGIAN A — MENYIAPKAN SUPABASE

## 1. Buat project Supabase

1. Masuk ke dashboard Supabase.
2. Buat project baru.
3. Pilih nama project, password database, dan region terdekat.
4. Tunggu project selesai dibuat.

## 2. Aktifkan Anonymous Sign-In

Di dashboard Supabase, buka pengaturan **Authentication** dan aktifkan **Anonymous Sign-Ins**.

Aplikasi ini sengaja memakai Anonymous Auth agar siswa tidak perlu mendaftar email/password.

> Penting: Anonymous Auth berbeda dengan `anon key`. Siswa yang sudah anonymous sign-in memiliki user ID dan menggunakan role database `authenticated`.

## 3. Buat tabel dan Row Level Security

1. Buka **SQL Editor** di Supabase.
2. Buka file `supabase/schema.sql` dari paket ini.
3. Salin seluruh isi file.
4. Tempel ke SQL Editor.
5. Klik **Run**.
6. Pastikan tidak ada error.

Script tersebut membuat:

### `student_state`
Menyimpan satu state terbaru per user/browser:
- `user_id`
- `student_name`
- `class_name`
- `app_state`
- `updated_at`

### `evaluation_results`
Menyimpan satu row untuk setiap percobaan evaluasi:
- `attempt_id`
- `user_id`
- `student_name`
- `class_name`
- `score`
- `category`
- `answers`
- `created_at`

RLS membatasi setiap siswa agar hanya dapat membaca/menulis data milik `auth.uid()`-nya sendiri.

## 4. Ambil Project URL dan Publishable Key

Cari di dashboard Supabase bagian API/Connect project:

- **Project URL**, contoh:
  `https://abcdefghijkl.supabase.co`
- **Publishable Key** atau **anon key** untuk aplikasi browser.

**JANGAN gunakan `service_role` key.**

## 5. Isi `public/supabase-config.js`

Buka:

```text
public/supabase-config.js
```

Ubah:

```js
window.SUPABASE_CONFIG = {
  url: "https://YOUR_PROJECT_REF.supabase.co",
  key: "YOUR_PUBLISHABLE_OR_ANON_KEY"
};
```

menjadi, misalnya:

```js
window.SUPABASE_CONFIG = {
  url: "https://abcdefghijkl.supabase.co",
  key: "sb_publishable_xxxxxxxxxxxxxxxxx"
};
```

atau anon key browser yang diberikan project Anda.

Publishable/anon key memang digunakan di frontend. Keamanan data tetap bergantung pada RLS. Jangan pernah menaruh `service_role` key di GitHub.

---

# BAGIAN B — UJI LOKAL SEBELUM GITHUB

Jangan membuka `index.html` hanya dengan `file://` jika ingin menguji perilaku web secara realistis.

Jika Python tersedia, dari folder project jalankan:

```bash
cd public
python -m http.server 8080
```

Kemudian buka:

```text
http://localhost:8080
```

Uji:

1. Isi Nama.
2. Pilih 9A/9B.
3. Selesaikan satu planet.
4. Refresh browser.
5. Pastikan progres tetap ada.
6. Selesaikan evaluasi.
7. Lihat header: status cloud seharusnya berubah menjadi `☁️ Tersinkron`.

Di Supabase Dashboard buka:

```text
Table Editor → evaluation_results
```

Pastikan row nilai muncul.

---

# BAGIAN C — UPLOAD KE GITHUB

## Cara termudah melalui web GitHub

### 1. Buat repository

Contoh nama:

```text
mpi-lingkaran
```

Untuk akun GitHub Free, repository publik paling sederhana untuk GitHub Pages.

### 2. Upload seluruh isi folder project

Yang harus ikut:

```text
public/
supabase/
.github/
README.md
```

**Jangan hanya upload `index.html`**, karena file workflow dan konfigurasi juga diperlukan.

Pastikan struktur `.github/workflows/pages.yml` tetap sama.

### 3. Pastikan branch utama bernama `main`

Workflow ini dipicu oleh:

```yaml
branches: ["main"]
```

Jika branch Anda memakai nama lain, ubah file workflow.

---

# BAGIAN D — AKTIFKAN GITHUB PAGES

1. Buka repository di GitHub.
2. Klik **Settings**.
3. Klik **Pages**.
4. Di bagian **Build and deployment**, pilih:
   **Source → GitHub Actions**.
5. Kembali ke tab **Actions**.
6. Workflow **Deploy MPI to GitHub Pages** akan berjalan setelah push ke `main`.
7. Tunggu sampai statusnya hijau.
8. Kembali ke **Settings → Pages** untuk melihat URL situs.

Biasanya URL project Pages berbentuk:

```text
https://USERNAME.github.io/mpi-lingkaran/
```

File workflow hanya mengunggah folder `public`, sehingga file `schema.sql` dan README tidak ikut menjadi halaman web publik.

---

# BAGIAN E — TEST SETELAH ONLINE

Buka URL GitHub Pages dari HP.

## Test 1 — Login anonim

Saat halaman dibuka, aplikasi akan:

1. membuat/memuat Supabase anonymous session;
2. menampilkan status cloud di header;
3. tetap bisa berjalan dari localStorage jika internet putus.

Status yang dapat muncul:

- `☁️ Menyambungkan…`
- `☁️ Tersinkron`
- `☁️ Menyimpan…`
- `☁️ Offline — cache lokal`
- `☁️ Supabase belum dikonfigurasi`
- `☁️ Sinkronisasi bermasalah`

## Test 2 — Progress

1. Masuk sebagai siswa.
2. Selesaikan Planet 1.
3. Kembali ke menu.
4. Planet 2 harus terbuka.
5. Refresh halaman.
6. Planet 1 tetap selesai dan Planet 2 tetap terbuka.

## Test 3 — Evaluasi

1. Kerjakan evaluasi sampai selesai.
2. Pastikan nilai tampil.
3. Pastikan halaman hasil menunjukkan sinkronisasi Supabase.
4. Buka Supabase Table Editor.
5. Periksa `evaluation_results`.

## Test 4 — Offline

1. Setelah pernah membuka aplikasi online, putus internet.
2. Gunakan aplikasi.
3. State tetap disimpan ke localStorage.
4. Sambungkan internet kembali.
5. Aplikasi akan mencoba sinkron kembali.

---

# BAGIAN F — MELIHAT NILAI SISWA SEBAGAI GURU

Cara paling sederhana:

1. Buka Supabase Dashboard.
2. Pilih project.
3. Buka **Table Editor**.
4. Pilih tabel:
   `evaluation_results`.

Kolom penting:

- `student_name`
- `class_name`
- `score`
- `category`
- `created_at`

Anda dapat memfilter kelas 9A atau 9B langsung dari Table Editor.

SQL contoh untuk melihat nilai terbaru:

```sql
select
  student_name,
  class_name,
  score,
  category,
  created_at
from public.evaluation_results
order by created_at desc;
```

Per kelas:

```sql
select
  student_name,
  score,
  category,
  created_at
from public.evaluation_results
where class_name = '9A'
order by created_at desc;
```

---

# BAGIAN G — HAL PENTING TENTANG ANONYMOUS AUTH

Anonymous Auth sangat cocok jika:

- siswa tidak perlu punya akun;
- tiap siswa terutama memakai HP/browser sendiri;
- ingin onboarding cepat.

Namun anonymous session tersimpan di browser. Jika siswa:

- menghapus data browser/site;
- memakai browser lain;
- memakai perangkat lain;

maka Supabase akan melihatnya sebagai anonymous user baru.

Untuk kelas di mana perangkat sering dipakai bergantian oleh banyak siswa, gunakan tombol **HAPUS DATA LOKAL / mulai sebagai siswa baru** sebelum siswa berikutnya memakai perangkat. Versi aplikasi ini juga meminta Supabase membuat anonymous session baru ketika data lokal dihapus.

Jika di masa depan Anda ingin siswa bisa pindah perangkat, gunakan login permanen seperti email/password, magic link, atau Google OAuth.

---

# BAGIAN H — KEAMANAN

## Aman untuk frontend

Boleh berada di `supabase-config.js`:

- Supabase Project URL
- Publishable Key
- anon key frontend

## Tidak boleh berada di frontend/GitHub

Jangan pernah simpan:

- `service_role` key
- password database
- secret JWT
- private API key lain

`service_role` dapat melewati RLS dan harus hanya digunakan di server/backend terpercaya.

## Mengapa RLS penting?

Frontend GitHub Pages bersifat publik. Pengunjung bisa melihat JavaScript dan publishable key. RLS adalah lapisan yang memastikan request database hanya dapat mengakses row yang diizinkan.

---

# BAGIAN I — OPSIONAL: CAPTCHA

Supabase merekomendasikan perlindungan tambahan seperti CAPTCHA untuk mengurangi penyalahgunaan anonymous sign-in pada situs publik.

Untuk tahap awal penggunaan kelas, Anda bisa menjalankan versi ini dahulu. Jika URL disebarkan secara luas, pertimbangkan mengaktifkan CAPTCHA di pengaturan Auth Supabase dan menambahkan token CAPTCHA pada proses anonymous sign-in.

---

# TROUBLESHOOTING

## 1. Header menunjukkan "Supabase belum dikonfigurasi"

Periksa:

```text
public/supabase-config.js
```

Pastikan placeholder sudah diganti.

## 2. Anonymous sign-in gagal

Pastikan Anonymous Sign-In sudah diaktifkan di Supabase Authentication settings.

Buka DevTools browser → Console untuk melihat error.

## 3. Error permission/RLS

Jalankan ulang:

```text
supabase/schema.sql
```

Pastikan policies dan grants sudah berhasil dibuat.

## 4. Nilai tampil tetapi tidak masuk tabel

Periksa:

- internet aktif;
- header cloud;
- tabel `evaluation_results`;
- RLS;
- browser Console;
- Project URL dan key benar.

## 5. GitHub Pages 404

Periksa:

- workflow Actions berhasil;
- Settings → Pages → Source = GitHub Actions;
- branch `main`;
- file `.github/workflows/pages.yml` ada.

## 6. Perubahan belum muncul

Lihat tab **Actions** dan tunggu deployment selesai. Browser juga dapat menyimpan cache; coba hard refresh.

---

# FILE UTAMA

Untuk mengubah materi/tampilan:

```text
public/index.html
```

Untuk mengubah koneksi Supabase:

```text
public/supabase-config.js
```

Untuk database/RLS:

```text
supabase/schema.sql
```

Untuk deployment GitHub Pages:

```text
.github/workflows/pages.yml
```
