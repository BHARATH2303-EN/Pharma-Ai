from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional
import sqlite3, os, re, io
from datetime import datetime, date

DB_PATH = os.path.join(os.path.dirname(__file__), "pharmaai.db")
app = FastAPI(title="PharmaAI API", version="1.0.0",
              description="Educational pharmacy practice prototype. Not for clinical decision-making.")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict to your app domain before deployment.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    with db() as con:
        con.executescript("""
        CREATE TABLE IF NOT EXISTS medicines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            generic_name TEXT NOT NULL,
            brand_examples TEXT DEFAULT '',
            drug_class TEXT DEFAULT '',
            uses TEXT DEFAULT '',
            common_side_effects TEXT DEFAULT '',
            precautions TEXT DEFAULT '',
            storage TEXT DEFAULT ''
        );
        CREATE TABLE IF NOT EXISTS interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            drug_a TEXT NOT NULL,
            drug_b TEXT NOT NULL,
            severity TEXT NOT NULL,
            description TEXT NOT NULL,
            recommendation TEXT NOT NULL,
            reference_note TEXT DEFAULT ''
        );
        CREATE TABLE IF NOT EXISTS adrs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_code TEXT NOT NULL,
            medicine TEXT NOT NULL,
            reaction TEXT NOT NULL,
            onset_date TEXT DEFAULT '',
            seriousness TEXT DEFAULT 'Not assessed',
            reporter_notes TEXT DEFAULT '',
            created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS adherence (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_code TEXT NOT NULL,
            medicine TEXT NOT NULL,
            instructions TEXT NOT NULL,
            reminder_time TEXT DEFAULT '',
            created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS dose_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            adherence_id INTEGER NOT NULL,
            dose_date TEXT NOT NULL,
            status TEXT NOT NULL,
            FOREIGN KEY(adherence_id) REFERENCES adherence(id)
        );
        """)
        count = con.execute("SELECT COUNT(*) FROM medicines").fetchone()[0]
        if count == 0:
            seed = [
                ("Paracetamol", "Dolo; Crocin (examples)", "Analgesic / antipyretic",
                 "Relief of pain and fever", "Nausea; rash (uncommon)", "Avoid duplicate paracetamol-containing products; liver disease requires professional review.", "Store as per product label."),
                ("Ibuprofen", "Brufen (example)", "NSAID",
                 "Pain, inflammation and fever", "Dyspepsia; nausea", "GI bleeding, kidney disease, pregnancy and other risk factors require professional review.", "Store as per product label."),
                ("Amoxicillin", "Various brands", "Penicillin antibiotic",
                 "Treatment of susceptible bacterial infections", "Diarrhoea; nausea; rash", "Check penicillin allergy and use only when prescribed.", "Store as per product label."),
                ("Metformin", "Various brands", "Biguanide antidiabetic",
                 "Type 2 diabetes management", "GI upset; diarrhoea", "Renal function and acute illness considerations require clinician review.", "Store as per product label."),
                ("Warfarin", "Various brands", "Vitamin K antagonist anticoagulant",
                 "Prevention and treatment of thromboembolic conditions", "Bleeding", "Requires INR monitoring and careful interaction review. Never change dose without prescriber advice.", "Store as per product label."),
                ("Aspirin", "Various brands", "Antiplatelet / NSAID",
                 "Uses depend on formulation and indication", "Dyspepsia; bleeding", "Bleeding risk, allergy and age-related precautions require professional review.", "Store as per product label."),
                ("Omeprazole", "Various brands", "Proton pump inhibitor",
                 "Acid-related disorders", "Headache; abdominal discomfort", "Check indication, duration and other medicines with a pharmacist.", "Store as per product label.")
            ]
            con.executemany("""INSERT INTO medicines
                (generic_name,brand_examples,drug_class,uses,common_side_effects,precautions,storage)
                VALUES (?,?,?,?,?,?,?)""", seed)
        count = con.execute("SELECT COUNT(*) FROM interactions").fetchone()[0]
        if count == 0:
            seed_i = [
                ("Warfarin", "Ibuprofen", "High",
                 "Concurrent use may increase bleeding risk.",
                 "Avoid self-medication; obtain prompt prescriber/pharmacist review. Do not stop prescribed treatment on your own.",
                 "Educational demo record; verify against current authoritative interaction references."),
                ("Warfarin", "Aspirin", "High",
                 "Concurrent use may increase bleeding risk.",
                 "Requires prescriber-directed risk assessment and monitoring. Do not start or stop either medicine without advice.",
                 "Educational demo record; verify against current authoritative interaction references."),
                ("Aspirin", "Ibuprofen", "Moderate",
                 "Concurrent use may increase gastrointestinal adverse effects; ibuprofen may also interfere with aspirin's antiplatelet effect depending on timing and formulation.",
                 "Ask a pharmacist or prescriber to review the combination and timing.",
                 "Educational demo record; verify against current authoritative interaction references.")
            ]
            con.executemany("""INSERT INTO interactions
                (drug_a,drug_b,severity,description,recommendation,reference_note)
                VALUES (?,?,?,?,?,?)""", seed_i)

init_db()

class InteractionRequest(BaseModel):
    medicines: list[str] = Field(min_length=2, max_length=20)

class CounsellingRequest(BaseModel):
    medicine: str
    instructions: str = ""
    language: str = "English"

class ADRRequest(BaseModel):
    patient_code: str = Field(min_length=1, max_length=40)
    medicine: str = Field(min_length=1, max_length=120)
    reaction: str = Field(min_length=1, max_length=1000)
    onset_date: str = ""
    seriousness: str = "Not assessed"
    reporter_notes: str = ""

class AdherenceRequest(BaseModel):
    patient_code: str = Field(min_length=1, max_length=40)
    medicine: str = Field(min_length=1, max_length=120)
    instructions: str = Field(min_length=1, max_length=300)
    reminder_time: str = ""

class DoseLogRequest(BaseModel):
    dose_date: str
    status: str

class AssistantRequest(BaseModel):
    question: str = Field(min_length=1, max_length=1000)
    language: str = "English"

@app.get("/health")
def health():
    return {"status": "ok", "service": "PharmaAI API", "mode": "educational prototype"}

@app.get("/medicines")
def list_medicines(q: str = ""):
    with db() as con:
        if q.strip():
            term = f"%{q.strip()}%"
            rows = con.execute("""SELECT * FROM medicines
                WHERE generic_name LIKE ? OR brand_examples LIKE ? OR drug_class LIKE ?
                ORDER BY generic_name LIMIT 100""", (term, term, term)).fetchall()
        else:
            rows = con.execute("SELECT * FROM medicines ORDER BY generic_name LIMIT 100").fetchall()
    return [dict(r) for r in rows]

@app.get("/medicines/{medicine_id}")
def medicine_detail(medicine_id: int):
    with db() as con:
        row = con.execute("SELECT * FROM medicines WHERE id=?", (medicine_id,)).fetchone()
    if not row:
        raise HTTPException(404, "Medicine not found")
    return dict(row)

@app.post("/interactions/check")
def check_interactions(payload: InteractionRequest):
    names = [x.strip() for x in payload.medicines if x.strip()]
    if len(names) < 2:
        raise HTTPException(400, "Enter at least two medicine names.")
    found = []
    with db() as con:
        rows = con.execute("SELECT * FROM interactions").fetchall()
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            a, b = names[i].lower(), names[j].lower()
            for r in rows:
                if {a, b} == {r["drug_a"].lower(), r["drug_b"].lower()}:
                    found.append(dict(r))
    return {
        "checked_medicines": names,
        "matches": found,
        "message": ("Potential interaction record(s) found. Pharmacist/prescriber review is required."
                    if found else "No matching record in this small demo database. This does NOT mean the combination is safe."),
        "disclaimer": "Dataset is incomplete and educational only. Verify all combinations using an authoritative current reference."
    }

@app.post("/counselling")
def counselling(payload: CounsellingRequest):
    lang = payload.language.lower()
    if lang not in ("english", "tamil"):
        lang = "english"
    with db() as con:
        row = con.execute("SELECT * FROM medicines WHERE lower(generic_name)=lower(?)",
                          (payload.medicine.strip(),)).fetchone()
    if not row:
        return {"medicine": payload.medicine, "language": lang,
                "counselling": "Medicine not found in the demo database. Please verify the medicine and consult a pharmacist.",
                "source": "Local demo database"}
    if lang == "tamil":
        text = (
            f"மருந்து: {row['generic_name']}\n"
            f"மருந்தின் வகை: {row['drug_class']}\n"
            f"பயன்பாடு: {row['uses']}\n"
            f"பொதுவான பக்கவிளைவுகள்: {row['common_side_effects']}\n"
            f"முன்னெச்சரிக்கை: {row['precautions']}\n"
            f"உங்கள் மருத்துவர் அல்லது மருந்தாளரின் அறிவுறுத்தலின்படி மட்டுமே பயன்படுத்தவும்."
        )
    else:
        text = (
            f"Medicine: {row['generic_name']}\n"
            f"Class: {row['drug_class']}\n"
            f"General use: {row['uses']}\n"
            f"Common side effects: {row['common_side_effects']}\n"
            f"Precautions: {row['precautions']}\n"
            "Use only according to the instructions provided by your prescriber or pharmacist."
        )
    if payload.instructions.strip():
        text += ("\n\nPrescription instructions provided for review: " + payload.instructions.strip())
    return {"medicine": row["generic_name"], "language": lang, "counselling": text,
            "source": "Local demo medicine database",
            "note": "Template-generated educational information. Verify before counselling."}

@app.post("/adrs")
def create_adr(payload: ADRRequest):
    with db() as con:
        cur = con.execute("""INSERT INTO adrs
            (patient_code,medicine,reaction,onset_date,seriousness,reporter_notes,created_at)
            VALUES (?,?,?,?,?,?,?)""",
            (payload.patient_code, payload.medicine, payload.reaction, payload.onset_date,
             payload.seriousness, payload.reporter_notes, datetime.utcnow().isoformat()))
        new_id = cur.lastrowid
    return {"id": new_id, "message": "Suspected ADR record saved for pharmacist review."}

@app.get("/adrs")
def list_adrs():
    with db() as con:
        rows = con.execute("SELECT * FROM adrs ORDER BY id DESC LIMIT 200").fetchall()
    return [dict(r) for r in rows]

@app.post("/adherence")
def create_adherence(payload: AdherenceRequest):
    with db() as con:
        cur = con.execute("""INSERT INTO adherence
            (patient_code,medicine,instructions,reminder_time,created_at)
            VALUES (?,?,?,?,?)""",
            (payload.patient_code, payload.medicine, payload.instructions,
             payload.reminder_time, datetime.utcnow().isoformat()))
        new_id = cur.lastrowid
    return {"id": new_id, "message": "Medication schedule saved."}

@app.get("/adherence")
def list_adherence():
    with db() as con:
        rows = con.execute("SELECT * FROM adherence ORDER BY id DESC LIMIT 200").fetchall()
    return [dict(r) for r in rows]

@app.post("/adherence/{schedule_id}/log")
def log_dose(schedule_id: int, payload: DoseLogRequest):
    if payload.status not in ("Taken", "Missed", "Skipped"):
        raise HTTPException(400, "Status must be Taken, Missed, or Skipped.")
    with db() as con:
        exists = con.execute("SELECT id FROM adherence WHERE id=?", (schedule_id,)).fetchone()
        if not exists:
            raise HTTPException(404, "Schedule not found")
        cur = con.execute("INSERT INTO dose_logs (adherence_id,dose_date,status) VALUES (?,?,?)",
                          (schedule_id, payload.dose_date, payload.status))
    return {"id": cur.lastrowid, "message": "Dose log saved."}

@app.get("/adherence/{schedule_id}/logs")
def adherence_logs(schedule_id: int):
    with db() as con:
        rows = con.execute("SELECT * FROM dose_logs WHERE adherence_id=? ORDER BY id DESC",
                           (schedule_id,)).fetchall()
    return [dict(r) for r in rows]

@app.post("/assistant")
def assistant(payload: AssistantRequest):
    q = payload.question.lower()
    if payload.language.lower() == "tamil":
        answer = ("நான் கல்வி நோக்கத்திற்கான PharmaAI உதவியாளர். மருந்து அளவை மாற்றவோ, நோயைக் கண்டறியவோ முடியாது. "
                  "மருந்து தொடர்பான முடிவுகளுக்கு தகுதியான மருத்துவர் அல்லது மருந்தாளரை அணுகவும். "
                  "உங்கள் கேள்வியை மருந்தின் பொதுவான தகவல், சேமிப்பு அல்லது மருந்தாளர் ஆலோசனை தொடர்பாக கேட்கலாம்.")
    elif any(k in q for k in ["dose", "dosage", "how many", "increase", "decrease"]):
        answer = ("I cannot recommend or change a dose. Follow the prescription label and ask the prescriber or pharmacist "
                  "if instructions are unclear. If an extra dose may have been taken, seek urgent professional advice.")
    elif any(k in q for k in ["side effect", "adverse", "reaction"]):
        answer = ("Side effects depend on the medicine and the person. Check the medicine's approved patient information "
                  "and speak with a pharmacist. For severe symptoms such as difficulty breathing, collapse, or facial/throat "
                  "swelling, seek emergency medical care.")
    elif any(k in q for k in ["interaction", "together", "combine"]):
        answer = ("Use the Interaction Checker as an initial educational screen, then verify the full medication list, "
                  "dose, route, timing, conditions and current references with a pharmacist. The demo database is incomplete.")
    elif any(k in q for k in ["storage", "store", "keep"]):
        answer = ("Follow the storage instructions on the product label or package insert. Storage requirements vary by "
                  "product; ask a pharmacist if the label is unclear.")
    else:
        answer = ("I can provide general pharmacy education, but I cannot diagnose, prescribe, or change treatment. "
                  "For a medicine-specific answer, search the Drug Information module and verify with a pharmacist. "
                  "Do not enter personal or identifiable patient information.")
    return {"answer": answer, "mode": "rule-based educational assistant",
            "disclaimer": "Not a substitute for professional medical advice."}

@app.post("/prescriptions/analyze-text")
def analyze_prescription_text(payload: dict):
    text = str(payload.get("text", ""))[:10000]
    lines = [x.strip() for x in text.splitlines() if x.strip()]
    # Deliberately conservative: extraction only, no dose interpretation.
    candidates = []
    for line in lines:
        if re.search(r"[A-Za-z]", line):
            candidates.append({"raw_line": line, "needs_manual_verification": True})
    return {"extracted_lines": candidates,
            "review_note": "Text extraction only. Verify medicine, strength, dosage form, route, frequency and duration manually.",
            "warning": "Never dispense or act on OCR output without pharmacist verification."}

@app.post("/prescriptions/ocr")
async def prescription_ocr(file: UploadFile = File(...)):
    content = await file.read()
    try:
        from PIL import Image
        import pytesseract
        image = Image.open(io.BytesIO(content))
        extracted = pytesseract.image_to_string(image)
        return {"available": True, "text": extracted,
                "warning": "OCR may be inaccurate. Manually verify every field."}
    except Exception:
        return {"available": False, "text": "",
                "message": "OCR engine is not installed or could not process this image. Use manual text entry.",
                "warning": "Do not rely on unverified OCR."}
