# PharmaAI – UG Final-Year Pharmacy Practice Prototype

A low-cost educational prototype with a Flutter Android/Web client and a Python FastAPI + SQLite backend.

## Included modules
1. Prescription Analyzer (manual text entry + optional server-side OCR)
2. Drug Information database
3. Drug Interaction Checker (curated demo dataset)
4. Patient Counselling (English/Tamil template-based output)
5. ADR / Pharmacovigilance recording
6. Medication Adherence schedules and dose logs
7. Pharmacy AI Assistant (educational, rule-based responses)

> SAFETY: This is an educational prototype, not a clinical decision system. The sample database is incomplete and must not be used to make treatment decisions. A negative interaction result does not prove that a combination is safe. A pharmacist must independently verify all prescription details and alerts. Do not enter identifiable patient information. Do not use the app to diagnose, prescribe, or change doses.

## Project structure

```text
PharmaAI/
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   └── README.md
├── flutter_app/
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       └── api_service.dart
└── README.md
```

## 1. Run the Python backend

Install Python 3.10 or newer.

### Windows
```powershell
cd backend
py -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### macOS / Linux
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Backend API documentation: http://127.0.0.1:8000/docs

SQLite database `pharmaai.db` is created automatically on first launch.

### Optional OCR
The prescription screen supports manual text entry everywhere. To enable image OCR on the backend, install the Tesseract OCR application for your operating system and install `pytesseract` and `Pillow`:
```bash
pip install pytesseract Pillow
```
Then install the Tesseract executable and ensure it is on PATH. OCR quality varies; always verify extracted text manually. If OCR is unavailable, the app returns a helpful message and manual entry still works.

## 2. Run Flutter app

Install Flutter SDK and Android Studio (for Android) or Chrome (for Web).

```bash
cd flutter_app
flutter pub get
```

### Web
Start the backend, then:
```bash
flutter run -d chrome
```
Web uses `http://127.0.0.1:8000` by default.

### Android emulator
Start the backend on the computer and run:
```bash
flutter run
```
The app uses `http://10.0.2.2:8000` for the Android emulator.

### Physical Android phone
1. Connect phone and computer to the same Wi-Fi network.
2. Find your computer's local IPv4 address (for example `192.168.1.5`).
3. Run:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000
```
4. Allow port 8000 through your computer firewall if prompted.

For a deployed web app, change the API URL to your HTTPS backend URL:
```bash
flutter build web --dart-define=API_BASE_URL=https://your-api.example.com
```

## 3. Android internet permission

For Android, ensure `android/app/src/main/AndroidManifest.xml` contains this line inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
For local HTTP development only, add `android:usesCleartextTraffic="true"` to the `<application ...>` element. Do not use cleartext HTTP in production.

## 4. Test the backend
Open `http://127.0.0.1:8000/docs` and try:
- `GET /health`
- `GET /medicines`
- `POST /interactions/check`
- `POST /counselling`
- `POST /adrs`
- `POST /adherence`
- `POST /assistant`

## 5. Academic evaluation suggestions
- Build a ground-truth set of simulated prescriptions and have a pharmacist review it.
- Measure OCR character/field accuracy against manually transcribed text.
- Evaluate interaction alerts against a pharmacist-verified reference dataset.
- Have pharmacy faculty assess counselling output for correctness, completeness, and readability.
- Conduct usability testing with institutional permission and informed consent.
- Report sensitivity, specificity, precision, and response time where appropriate. Do not claim clinical effectiveness from a small prototype.

## 6. Before any real-world use
Replace the demo medicine and interaction records with a properly licensed, authoritative, locally relevant dataset. Add authentication, role-based access, audit logs, encryption, secure hosting, privacy notices, backups, and institutional/ethics approvals as applicable. Do not upload identifiable patient records to an external AI service without authorization and appropriate safeguards.
