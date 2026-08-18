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

## ASPECTS region diagram (Stroke Code decision support)

The ASPECTS template shown in the Stroke Code **ASPECTS — How to calculate** card is:

- **Asset name:** `AspectsTemplate`
- **Source:** Schröder J, Thomalla G. *A Critical Review of Alberta Stroke Program Early CT Score for Evaluation of Acute Stroke Imaging.* Front Neurol. 2017;7:245. **Figure 2** (ganglionic and supraganglionic slices with regions C, L, IC, I, M1–M6).
- **License:** [Creative Commons Attribution 4.0 (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/) — use permitted with attribution.
- **PMC article:** <https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5226934/>
- **Original template:** Barber PA et al. Lancet. 2000;355(9216):1670-1674.

Embedded for clinician training / education only (see [DISCLAIMER.md](DISCLAIMER.md)).

## pc-ASPECTS (posterior-circulation ASPECTS)

The Stroke Code **pc-ASPECTS** score and region list follow:

- **Puetz V et al.** Extent of hypoattenuation on CT angiography source images predicts functional outcome in patients with basilar artery occlusion. *Stroke.* 2008;39(9):2485-2490.
- 10-point score: left/right thalamus, left/right cerebellum, left/right PCA cortex (1 point each); midbrain and pons (2 points each). Start at 10; subtract for early ischemic change.
- Basilar-occlusion EVT trials (ATTENTION, BAOCHE) typically enrolled pc-ASPECTS ≥ 6.

The **pc-ASPECTS region diagram** shown in **pc-ASPECTS — How to calculate** is:

- **Asset name:** `PcAspectsTemplate`
- **Source:** Khatibi K, Nour M, Tateshima S, Jahan R, Duckwiler G, Saver JL, Szeder V. *Posterior Circulation Thrombectomy—pc-ASPECT Score Applied to Preintervention Magnetic Resonance Imaging Can Accurately Predict Functional Outcome.* World Neurosurg. 2019;129:e566-e571. **Figure 1** (axial slices at pons/cerebellum, midbrain, and thalami/occipital lobes with point values).
- **DOI:** [10.1016/j.wneu.2019.05.217](https://doi.org/10.1016/j.wneu.2019.05.217)
- **ScienceDirect:** <https://www.sciencedirect.com/science/article/abs/pii/S1878875019314949>

Embedded for clinician training / education only (see [DISCLAIMER.md](DISCLAIMER.md)). This project is not affiliated with or endorsed by the authors or Elsevier / World Neurosurgery.

## Patient-language content (NIHSS prompts, consent script, back-translation)

The Spanish, Haitian Creole, and (where applicable) English patient-facing strings — NIHSS prompts in `NIHSSStrokeScale/Models/NIHSS/NIHSSData.swift`, IV thrombolysis consent script in `NIHSSStrokeScale/Models/StrokeCode/StrokeCodeConsent.swift`, and the patient-speech back-translation tables in `NIHSSStrokeScale/Services/PatientResponseService.swift` — are **training aids, not certified medical translations**.

- They have **not** been reviewed by a certified medical interpreter or translator.
- They are intended to help English-speaking clinician trainees practice running the NIHSS and a stroke-code workflow with non-English-speaking patients in a simulation setting.
- For real patient care, use your institution's qualified medical interpreters and your institution's approved consent documents.

The Haitian Creole content in particular reflects general Kreyòl ayisyen conventions; regional preferences vary, and the Apple text-to-speech voice for `ht-HT` is not available on every device — the app falls back to French (`fr`) when no Creole voice is installed, which is an audio approximation only.
