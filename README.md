# 🌌 Lumen Parallax Image Explorer (Flutter)

A modern, high-performance Flutter application for exploring and searching high-definition photography with multi-layered **Parallax Effects**, fluid micro-animations, and a sleek dark luxury UI aesthetic.

---

## ✨ Fitur Utama (Key Features)

### 1. Multi-Layer Parallax Effects
- **FlowDelegate Scroll Parallax**: Menggunakan Flutter `Flow` dan `FlowDelegate` resmi untuk pergerakan gambar latar yang sangat halus (60/120 FPS hardware-accelerated) mengikuti posisi kartu di dalam scroll viewport.
- **Horizontal 3D Carousel Parallax**: Carousel kurasi di bagian atas dengan efek pergeseran internal gambar (`PageView` delta offset) berkecepatan ganda dan animasi skala bertahap.
- **Interactive 3D Perspective Tilt**: Mode kartu grid dengan matriks 4D (`Matrix4.identity()..setEntry(3, 2, 0.0018)..rotateX(..)..rotateY(..)`) yang merespons sentuhan jari (pan) atau kursor mouse (hover) dengan specular light glint dan label mengambang (holographic depth).
- **Parallax Header Detail View**: Halaman detail dengan latar belakang berkecepatan 0.45x dari scroll, transisi Hero, dan interactive pinch-to-zoom.

### 2. Powerful Search & Filtering
- **Debounced Instant Search**: Pencarian cerdas secara langsung dengan penundaan debounce (350ms) agar performa tetap responsif.
- **Kategori Preset Cepat**: Filter instan berdasarkan tema (Cyberpunk, Nature, Space, Architecture, Anime, Minimalist, Vehicles).
- **Filter Sheet**: Opsi orientasi (Landscape, Portrait, Semua), pengurutan (Terpopuler, Terbaru), dan integrasi API.

### 3. Pixabay API Integration & Offline Fallback
- **Pixabay Live Search**: Terintegrasi langsung dengan API Pixabay menggunakan API Key resmi (`17389955-eb167990fe4e1dae1ad3932a1`) untuk mencari jutaan gambar berkualitas tinggi secara live.
- **Curated Offline Fallback**: Dilengkapi koleksi kurasi HD resolusi tinggi sebagai fallback otomatis jika perangkat offline atau koneksi jaringan terputus.

### 4. Fitur Tambahan & UI Premium
- **Simulasi Pratinjau Wallpaper HP**: Mode khusus di halaman detail untuk melihat bagaimana foto tampak saat dijadikan layar kunci ponsel (menampilkan jam lockscreen 09:41, tanggal, status bar, dan tombol senter).
- **Kamera & Spesifikasi EXIF**: Menampilkan model kamera, panjang fokus, aperture, dan ISO.
- **Koleksi Favorit (Persistent)**: Menyimpan foto yang disukai ke penyimpanan lokal (`shared_preferences`) dengan animasi detak jantung dan counter badge.
- **Mode Tampilan Ganda**: Tombol pengubah tampilan antara *Feed Parallax* dan *3D Tilt Grid*.

---

## 🛠️ Struktur Proyek

```
lib/
├── main.dart                      # Inisialisasi aplikasi, tema, dan status bar
├── models/
│   └── image_item.dart            # Data model foto, rasio aspek, EXIF, dan JSON serialization
├── services/
│   └── image_service.dart         # Layanan pencarian online & dataset kurasi, manajemen favorit
├── theme/
│   └── app_theme.dart             # Palet warna gelap obsidian, gradien neon, tipografi Outfit & Plus Jakarta Sans
├── widgets/
│   ├── parallax_card.dart         # Kartu vertikal dengan FlowDelegate parallax scroll
│   ├── parallax_carousel.dart     # Carousel horizontal dengan 3D PageView parallax
│   ├── parallax_3d_card.dart      # Kartu 3D tilt perspective interaktif (gesture & hover)
│   ├── search_bar_widget.dart     # Bar pencarian mengambang dan pill filter kategori
│   ├── filter_sheet.dart          # Modal bottom sheet untuk orientasi & filter lanjutan
│   └── shimmer_placeholder.dart   # Efek shimmer skeleton loading
└── screens/
    ├── home_screen.dart           # Layar utama (pencarian, feed parallax, grid 3D)
    ├── image_detail_screen.dart   # Layar detail dengan parallax header, zoom & wallpaper mockup
    └── favorites_screen.dart      # Layar daftar foto favorit tersimpan
```

---

## 🚀 Cara Menjalankan (Getting Started)

### Prasyarat
- Flutter SDK 3.19+ (Diuji pada Flutter 3.44 / Dart 3.12)
- Koneksi internet untuk memuat gambar resolusi tinggi

### Menjalankan di Perangkat

1. **Jalankan di macOS Desktop**:
   ```bash
   flutter run -d macos
   ```

2. **Jalankan di Web (Chrome)**:
   ```bash
   flutter run -d chrome
   ```

3. **Jalankan di Android / iOS**:
   ```bash
   flutter run
   ```

---

## 📄 Lisensi & Kredit
- Gambar bersumber dari fotografer [Unsplash](https://unsplash.com) melalui CDN resolusi tinggi.
