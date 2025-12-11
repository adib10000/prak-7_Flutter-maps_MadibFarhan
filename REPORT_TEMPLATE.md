# Laporan Praktikum — Implementasi Fitur Peta Rekomendasi Kuliner

> Template laporan praktikum untuk mata kuliah Pengembangan Aplikasi Bergerak
>
> Isi laporan ini disusun agar mudah diisi: tinggal ganti placeholder dan tambahkan screenshot.

## Informasi Umum
- Nama  : [Nama Mahasiswa]
- NIM   : [NIM]
- Program Studi : [Program Studi]
- Mata Kuliah    : [Nama Mata Kuliah]
- Dosen Pengampu : [Nama Dosen]
- Tanggal Praktikum : [Tanggal]

## Judul Praktikum
Implementasi Peta Rekomendasi Kuliner — Penambahan Lokasi (GPS / Pilih di Peta)

## Tujuan
- Mengimplementasikan integrasi peta (flutter_map + OpenStreetMap).
- Menangani input lokasi dari pengguna (GPS atau titik peta).
- Mengirim rekomendasi ke server (MockAPI) dan menampilkan marker hasil penyimpanan.

## Alat dan Bahan
- Flutter SDK
- Android Studio / Emulator atau Chrome (web)
- Library: `flutter_map`, `geolocator`, `http`, `latlong2`, `flutter_svg`
- MockAPI untuk menyimpan data lokasi

## Langkah Implementasi (Ringkasan)
1. Menambahkan dependensi di `pubspec.yaml`.
2. Menambahkan izin lokasi di `AndroidManifest.xml`.
3. Membuat model `LocationModel` dengan parsing aman (double.tryParse).
4. Membuat `ApiService` untuk GET dan POST lokasi.
5. Membuat `MapPage` — menampilkan peta, marker, flow tambah lokasi, bottom sheet input.

## Hasil (Screenshot)
Sertakan screenshot yang menunjukkan peta penuh dengan rekomendasi.

- Nama file screenshot: `map_kampus4_filled.png`
- Lokasi file: `assets/screenshots/map_kampus4_filled.png`

Contoh penempatan gambar (Markdown):

```markdown
![Peta penuh - Kampus 4 UAD](assets/screenshots/map_kampus4_filled.png)
```

> Instruksi: Ambil screenshot dari aplikasi saat peta sudah berisi banyak marker (10-30 rekomendasi). Gunakan emulator atau mode web.

## Analisis
1. Validasi dan parsing data
   - Jelaskan pentingnya penggunaan `double.tryParse` pada `LocationModel.fromJson` untuk mencegah crash bila server mengirim nilai koordinat sebagai string atau nilai tidak valid.

2. Kinerja & UX
   - Tambahkan loading indicator saat fetch dan saat menyimpan.
   - Perhatikan clustering marker bila banyak marker di area kecil.

3. Keamanan & Robustness
   - Tangani error jaringan (timeout, non-200 responses).
   - Validasi input pengguna (nama tidak kosong, panjang maksimal).

## Diskusi
- Kelebihan pendekatan saat ini: cepat diimplementasikan, mengandalkan MockAPI untuk menyimpan data tanpa infrastruktur backend.
- Keterbatasan: data tidak realtime untuk pengguna lain kecuali polling atau implementasi sockets.
- Usulan perbaikan: gunakan Firestore / Realtime DB untuk update real-time; implementasikan marker clustering dan caching offline.

## Kesimpulan
- Aplikasi berhasil menampilkan rekomendasi kuliner pada peta dan memungkinkan pengguna menambah lokasi lewat GPS atau memilih titik di peta.
- Penggunaan `double.tryParse` pada model mengurangi crash akibat format data tak terduga.
- Untuk produksi, diperlukan backend yang mendukung real-time dan manajemen data lebih baik.

## Lampiran
- Potongan kode penting (contoh `LocationModel`):

```dart
class LocationModel {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;

  LocationModel({required this.id, required this.name, required this.description, required this.latitude, required this.longitude});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'].toString(),
      name: json['name'] ?? 'Warung Tanpa Nama',
      description: json['description'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
    );
  }
}
```

- Contoh request POST (JSON body):

```json
{
  "name": "Nasi Goreng Pak Kumis",
  "description": "Enak dan murah",
  "latitude": -7.257500,
  "longitude": 112.752100
}
```

---

> Jika Anda ingin, saya bisa generate versi PDF dari laporan ini (butuh konfirmasi dan screenshot).