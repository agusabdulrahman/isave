# iSaveUp

iSaveUp adalah aplikasi Flutter untuk mencatat income/expense, transfer antar akun, recurring transaction, dan monitoring budget bulanan.

![iSaveUp Screenshot](assets/docs/Screenshot%202026-05-14%20113110.png)

## Fitur Utama

- Autentikasi user (Supabase Auth)
- Pencatatan transaksi income/expense
- Transfer antar akun
- Recurring transaction (auto-create transaksi saat jatuh tempo)
- Budget bulanan dengan mode:
  - auto reset tiap bulan
  - manual set per bulan
- Edit dan hapus transaksi dari halaman Home
- Multi-currency (`USD`, `IDR`)

## Tech Stack

- Flutter (Material 3)
- Supabase (`supabase_flutter`)
- Google Fonts

## Struktur Folder `lib`

```text
lib/
  config/
  controller/
  model/
  routes/
  utils/
  view/
    app.dart
    core/
    home/
    wallet/
    goals/
    profile/
  widgets/
  main.dart
```

## Prasyarat

- Flutter SDK terpasang
- Project Supabase aktif
- Tabel database yang dibutuhkan sudah tersedia:
  - `profiles`
  - `accounts`
  - `categories`
  - `transactions`
  - `recurring_transactions`

## Konfigurasi

Saat ini URL dan anon key Supabase diset di:

- `lib/config/supabase_config.dart`

Untuk production, direkomendasikan pindahkan key ke env/secret management.

## Menjalankan Project

```bash
flutter pub get
flutter run
```

Untuk web:

```bash
flutter run -d chrome
```
Build release Android
```
flutter build appbundle --release
```

Hasil file:

```
build/app/outputs/bundle/release/app-release.aab
```

File .aab itu nanti yang di-upload ke Google Play Store.


## Command Saat Development

```text
r  Hot reload
R  Hot restart
h  List all available interactive commands
d  Detach (terminate "flutter run" but leave app running)
c  Clear screen
q  Quit
```

## Quality Check

```bash
dart format lib
flutter analyze
```

## Catatan

- Data load utama sudah difilter per user (`user_id`) untuk mencegah data tercampur antar akun user.
- Jika ada perubahan besar struktur file, lakukan full restart (bukan hanya hot restart) saat debug web.
