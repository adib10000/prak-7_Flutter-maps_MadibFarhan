# KulinerHunt — Aplikasi Peta Rekomendasi Kuliner (Flutter)

Deskripsi singkat
-----------------
KulinerHunt adalah prototipe aplikasi Flutter yang menampilkan lokasi rekomendasi tempat makan pada peta (menggunakan `flutter_map` + OpenStreetMap). Pengguna dapat menambahkan rekomendasi baru menggunakan GPS atau memilih titik pada peta (pin-point), mengisi nama & deskripsi, lalu menyimpan rekomendasi tersebut ke MockAPI. Aplikasi menampilkan marker interaktif yang dipoles dan menyediakan fitur pencarian, kontrol peta, serta bottom sheet modern untuk input.

Isi README ini
----------------
- Persiapan proyek (dependencies & izin)
- Struktur berkas penting
- Cara menjalankan (dev)
- Penjelasan implementasi singkat (model, service, UI)
- Jawaban singkat tugas laporan praktikum

Persiapan & Dependensi
----------------------
Pastikan Flutter sudah terpasang (stable channel) dan environment siap.

Di `pubspec.yaml` (sudah diperbarui) terdapat dependensi utama:
- `flutter_map` (menampilkan peta)
- `latlong2` (tipe koordinat)
- `http` (request HTTP)
- `geolocator` (akses GPS)
- `flutter_svg` (render SVG inline)

Tambahkan izin Android di `android/app/src/main/AndroidManifest.xml` (sudah ditambahkan):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Menjalankan aplikasi (development)
---------------------------------
1. Buka terminal di root project (`c:\flutter_maps`).
2. Install dependensi:
```powershell
flutter pub get
```
3. Jalankan pada perangkat / emulator / web:
```powershell
flutter run
```

Catatan: pada Windows, bila menggunakan plugin native dan build gagal karena symlink, aktifkan Developer Mode.

Struktur berkas (ringkasan)
--------------------------
- `lib/main.dart` — entry point, tema oranye, buka `MapPage`.
- `lib/pages/map_page.dart` — implementasi peta, marker, flow tambah rekomendasi (GPS / pilih di peta), bottom sheet, search, map controls.
- `lib/models/location_model.dart` — model `LocationModel` (safe parsing menggunakan `double.tryParse`).
- `lib/services/api_service.dart` — `getLocations()` & `addLocation()` (gunakan URL MockAPI Anda).
- `assets/` — (opsional) sebelumnya ada SVG, namun pada versi ini SVG di-embed di dalam `map_page.dart` untuk menghindari masalah bundling.

Implementasi singkat
--------------------
- Model: `LocationModel.fromJson(...)` mengamankan parsing latitude/longitude yang kadang dikirim sebagai string.
- Service: `ApiService` melakukan GET untuk daftar lokasi dan POST untuk menambah rekomendasi.
- UI: `MapPage` mem-fetch data saat init, membangun `Marker` untuk setiap lokasi, menyediakan tombol `Rekomendasiin!` yang membuka pilihan (GPS / Pilih di Peta). Untuk input nama & deskripsi menggunakan Modal Bottom Sheet yang modern.


Praktikum
---------------------------------------------

1) Mengapa kita harus menggunakan `double.tryParse` pada model data?

Penjelasan singkat:
- Data koordinat dari server (MockAPI atau API eksternal) sering datang dalam format yang berbeda-beda: angka (number) atau string. Jika server mengirimkan nilai koordinat sebagai string (mis. `"-7.2575"`), pemanggilan `double.parse(json['latitude'])` akan berhasil jika nilai valid, tetapi apabila nilai tidak valid atau `null` maka `double.parse` akan melempar exception dan mematikan alur aplikasi.
- `double.tryParse(...)` akan mencoba mengonversi string ke `double` tetapi tidak melempar exception ketika parsing gagal; ia mengembalikan `null` jika gagal. Dengan memberikan fallback (mis. `double.tryParse(... ) ?? 0.0`) kita mencegah crash aplikasi dan dapat memberikan nilai default atau penanganan error lebih aman.

Keuntungan praktis:
- Mencegah aplikasi crash saat data tidak sesuai format.
- Memudahkan debugging dan validasi data sebelum digunakan di UI (mis. mem-filter lokasi non-valid).
- Memperkuat robustness aplikasi terhadap data dari luar yang tidak dapat dipercaya.

2) Jelaskan alur data dari input pengguna hingga muncul di peta teman lain

Langkah-langkah alur data (end-to-end):

- 1. Input pengguna: pada aplikasi, pengguna memilih tombol `Rekomendasiin!` → memilih `Gunakan GPS` atau `Pilih di Peta`.
  - Jika `Gunakan GPS`: aplikasi meminta permission lokasi, membaca posisi saat ini lewat `Geolocator.getCurrentPosition()`.
  - Jika `Pilih di Peta`: pengguna mengetuk peta atau memindahkan pin sementara untuk menentukan koordinat target.

- 2. Pengguna mengisi nama tempat (dan deskripsi) pada modal bottom sheet, lalu menekan `Simpan`.

- 3. Aplikasi membuat objek `LocationModel` yang berisi `name`, `description`, `latitude`, `longitude` (dan id kosong/otomatis), lalu memanggil `ApiService.addLocation(model)`.
  - `ApiService.addLocation` mengirim HTTP POST ke endpoint MockAPI (mis. `https://<your-mockapi>/api/v1/locations`) dengan body JSON hasil `model.toJson()`.

- 4. Server MockAPI menyimpan data baru dan mengembalikan response sukses (201 Created) beserta object yang disimpan (tergantung konfigurasi).

- 5. Aplikasi menutup bottom sheet, dan pada kondisi sukses memanggil `_fetchLocations()` lagi untuk mem-refresh daftar lokasi dari server (melakukan HTTP GET ke endpoint yang sama).

- 6. `_fetchLocations()` menerima daftar lokasi terbaru dari server, mem-parsing JSON menjadi `LocationModel` menggunakan `LocationModel.fromJson(...)` (di sini `double.tryParse` mencegah crash jika koordinat berupa string). Aplikasi membangun ulang daftar `Marker` dan memanggil `setState()` sehingga map mengalami re-render dan menampilkan marker baru.

- 7. Teman lain (user lain) yang membuka aplikasi akan menerima data baru setelah mereka melakukan refresh/initial fetch. Ini dapat dilakukan dengan beberapa pendekatan:
  - Polling: klien melakukan `GET /locations` saat buka aplikasi ataupun saat melakukan refresh manual/otomatis periodik (skenario sederhana, sudah diimplementasikan pada `MapPage` dengan tombol refresh dan pemanggilan `_fetchLocations`).
  - Real-time (lebih baik): server mengirimkan notifikasi push / websocket / WebRTC saat ada lokasi baru, sehingga semua klien menerima update instant dan menambahkan marker tanpa refresh manual.

Catatan implementasi
--------------------
- Pada implementasi sederhana ini, distribusi ke teman lain bergantung pada mereka memanggil `GET` (refresh) atau saat mereka membuka app (in `initState`). Untuk real-time, kita dapat menambahkan WebSocket atau layanan push (Firebase Realtime Database, Firestore + Cloud Functions, atau server socket) agar setiap klien menerima event saat ada penambahan lokasi baru.

Tambahan / Saran perbaikan
-------------------------
- Tambahkan validasi form (nama minimal, panjang deskripsi, UX untuk error response).
- Implementasikan clustering marker untuk menangani banyak marker agar peta tetap rapi.
- Tambahkan caching lokal (sqflite / hive) agar marker tetap terlihat saat offline.
- Ganti MockAPI ke server nyata atau gunakan Firebase untuk real-time.

Diagram Alur (ASCII)
---------------------
Alur data singkat dari input pengguna hingga tampil di peta klien lain:

    +------------+     (1) Input      +-----------+     (2) POST    +--------+
    |  Pengguna  | --------------->  |  Aplikasi | ---------------> | Server |
    |  (mobile)  |  "Simpan rekom"    | (Flutter) |   POST /locations | MockAPI|
    +------------+                    +-----------+                  +--------+
           |                                |                            |
           |                                |                            |
           |                                |                            |
           |                                v                            v
           |                         Simpan di server              Server menyimpan dan
           |                         (201 Created)                mengembalikan data baru
           |                                |                            |
           |                                | (3) GET /locations         |
           |                                | <--------------------------+
           |                                v
           |                       +-----------------+
           +-----------------------| Klien lain/     |
  (4) Sinkronisasi via polling    | Pengguna lain   |
                                  | (fetch data)    |
                                  +-----------------+

Keterangan langkah:
- (1) Pengguna memasukkan nama/deskripsi dan memilih koordinat (GPS atau pin)
- (2) Aplikasi mengirim POST ke endpoint MockAPI dengan body JSON lokasi
- (3) Semua klien bisa mengambil (GET) daftar lokasi terbaru dari server
- (4) Untuk real-time, gunakan WebSocket / push notifications supaya klien lain
  menerima update secara otomatis tanpa polling

