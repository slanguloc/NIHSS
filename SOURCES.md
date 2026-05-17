# Image and content sources

## Item 9 (Best Language) figures

The images used in the app for **NIHSS Item 9 — Best Language** (name objects, read sentences, describe picture) are sourced from:

**Mayo Clinic Proceedings.** 2006;81(4):476-480.

- **Asset names in app:** `Item9_Figure2`, `Item9_Figure3`, `Item9_Figure4`  
  (corresponding to the three sub-tasks: name objects, read sentences, describe picture).

- **Reference PDF:** `MayoClinicProc06-476-480.pdf`  
  (Mayo Clinic Proceedings 2006; 476-480).

These figures are used for **education and training only** (see [DISCLAIMER.md](DISCLAIMER.md)). This project is not affiliated with or endorsed by Mayo Clinic or Mayo Foundation.

## Item 9 — English images (NIH / NINDS standard NIHSS, March 2025)

The English-language images used for **NIHSS Item 9 — Best Language** are sourced from the official **NIH Stroke Scale (March 2025 edition)** published by the National Institute of Neurological Disorders and Stroke (NINDS):

- Source URL: <https://www.ninds.nih.gov/sites/default/files/2025-03/KnowStroke_NIHStrokeScale_March2025_508c.pdf>
- Asset names in app:
  - `Item9_Naming_English` — naming card (objects to name; page 11)
  - `Item9_Sentences_English` — sentences to read (page 12)
  - `Item9_Picture_English` — picture for description (page 10)

The NIH Stroke Scale is distributed by NINDS for clinical and educational use. The page-10 picture and the page-11 naming card carry an "© Apex Innovations" attribution within the NINDS document. These materials are embedded here **solely for clinician training / education purposes** (see [DISCLAIMER.md](DISCLAIMER.md)). This project is **not affiliated with or endorsed by** NIH, NINDS, or Apex Innovations.

If you redistribute this app to others, verify your local licensing posture for the NIH/NINDS materials before broad publication.

## Item 9 — Haitian Creole images (Best Language)

When **Kreyòl ayisyen** is selected for patient language, NIHSS Item 9 uses:

| Sub-task | Asset | Source |
|----------|-------|--------|
| 1. Name objects | `Item9_Naming_English` | Same NIH/NINDS naming card as English (see above) |
| 2. Read sentences | `Item9_Sentences_Creole` | App-generated card with standard NIHSS sentences translated to Haitian Creole (training aid; not an official NINDS translation) |
| 3. Describe picture | `Item9_Picture_English` | Same NIH/NINDS picture scene as English (see above) |

Spanish continues to use the Mayo Clinic Proceedings figures (`Item9_Figure2`, `Item9_Figure3`, `Item9_Figure4`).

## Patient-language content (NIHSS prompts, consent script, back-translation)

The Spanish, Haitian Creole, and (where applicable) English patient-facing strings — NIHSS prompts in `NIHSSStrokeScale/Models/NIHSS/NIHSSData.swift`, IV thrombolysis consent script in `NIHSSStrokeScale/Models/StrokeCode/StrokeCodeConsent.swift`, and the patient-speech back-translation tables in `NIHSSStrokeScale/Services/PatientResponseService.swift` — are **training aids, not certified medical translations**.

- They have **not** been reviewed by a certified medical interpreter or translator.
- They are intended to help English-speaking clinician trainees practice running the NIHSS and a stroke-code workflow with non-English-speaking patients in a simulation setting.
- For real patient care, use your institution's qualified medical interpreters and your institution's approved consent documents.

The Haitian Creole content in particular reflects general Kreyòl ayisyen conventions; regional preferences vary, and the Apple text-to-speech voice for `ht-HT` is not available on every device — the app falls back to French (`fr`) when no Creole voice is installed, which is an audio approximation only.
