# 🐾 Karuṇā — Phase 2: Flutter Wiring

This file documents the frontend improvements made during Phase 2 to wire the Flutter client application to the updated DB-backed backend.

---

## 🛠️ Flutter Gaps Completed

### 1. Page Response Handling (Paginated Lists)
Spring Boot backend returns paginated case, donation, and adoption logs as `Page` structures:
```json
{
  "content": [...],
  "totalElements": 12,
  "totalPages": 1
}
```
The Flutter services previously expected a raw JSON List (`data as List`), which threw runtime type cast exceptions. We added a generic `_extractContent` helper to safely extract items from either a paginated `content` block or fallback array:
- `CaseService.getAllCases()`
- `CaseService.getOpenCases()`
- `CaseService.getMyCases()`
- `DonationService.getDonationsForCase()`
- `AdoptionService.getAdoptionsForCase()`

### 2. Auto Image Upload Pipeline
We converted image handling in `report_flow.dart` from raw base64 data transmission to a hybrid pipeline:
- `CaseService.uploadImage()` accepts the local `photoPath` (from Flutter `image_picker`) and uploads it as a `multipart/form-data` file.
- The backend's new `/api/upload/image` endpoint saves the file and returns a public URL (`http://localhost:8081/uploads/...`).
- The public URL is then supplied in the `imageUrl` field of `cases.createCase()` rather than passing massive base64 payloads to database.

### 3. Extended Fields Support
Wired Flutter's creation step to save AI classification results into PostgreSQL:
- Added `firstAidSteps` (rules list) and `estimatedCostInr` parameters to `CaseService.createCase` and `CaseProvider.createCase`.
- Enabled `report_flow.dart` to submit these fields directly.

### 4. Status Update Fixes
Corrected `/advance` endpoint call mapping in `api_config.dart` to `/status` matching the backend controller.
Mapped statuses to uppercase string values (`ASSIGNED`, `DISCHARGED` etc.) as required by backend enums.

### 5. Notes / Treatment Updates
Configured `CaseService.addNote` to update case details via `PUT /api/cases/{id}` using the newly supported `notes` column instead of calling a non-existent `/notes` route.

### 6. Android Manifest Permissions
Added missing runtime permission definitions to `android/app/src/main/AndroidManifest.xml`:
- `android.permission.CAMERA`
- `android.permission.READ_EXTERNAL_STORAGE` (maxSdkVersion 32)
- `android.permission.READ_MEDIA_IMAGES`
- Camera feature hardware integration

---

## 🚀 How to Run the Flutter App

1. Ensure the Spring Boot backend is running (`http://localhost:8081`).
2. Make sure you have Flutter SDK installed and on your PATH.
3. Start an emulator or connect a device.
4. Execute:
   ```bash
   cd flutter
   flutter pub get
   flutter run
   ```

> [!TIP]
> To test on the Android Emulator, the `baseUrl` in `flutter/lib/config/api_config.dart` is pre-configured to `http://10.0.2.2:8081/api` (Android's alias to host localhost).
