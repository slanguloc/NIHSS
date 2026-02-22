# Zysquy — NIH Stroke Scale for non-English speaking patients

**Educational use only. Not intended for clinical use.**

iPhone app for **education and training** on the NIH Stroke Scale with support for **non-English speaking patients** (e.g. Spanish). It guides you through the full NIH Stroke Scale and provides **Spanish phrases to say or show** at each step for learning and practice purposes.

## Features

- **Full NIH Stroke Scale** — All 11 categories in order (1a, 1b, 1c, 2–11), with Motor Arm and Motor Leg for left and right.
- **Provider instructions in English** — What to do and how to score.
- **Spanish prompts for the patient** — Clear “say or show to patient” text so you can communicate during the exam.
- **One-tap scoring** — Large buttons for fast scoring during a stroke code.
- **Running total** — NIHSS total updates as you go and on the summary screen.
- **Summary** — Final score and item-by-item breakdown when you finish.

## How to open and run

1. Open **Xcode**.
2. **File → Open** and select the folder `NIHSSStrokeScale.xcodeproj` (inside this repo).
3. Choose the **NIHSSStrokeScale** scheme.
4. **Select an iPhone simulator:** In the toolbar, click the device menu next to the Run (▶) button. If it says **"Any iOS Device (arm64)"**, that is a build-only destination and will show *"A build only device cannot be used to run this target"*. Choose an **iPhone simulator** instead (e.g. **iPhone 16**, **iPhone 15**, **iPhone 14**).
5. Press **Run** (⌘R).

If you prefer to use a physical iPhone, connect it via USB, trust the computer on the device if prompted, then select your iPhone from the same device menu.

## If the build fails

- **"Requires a development team" or "Requires a provisioning profile"**  
  Xcode needs a signing identity to build. In the project navigator, select the **NIHSSStrokeScale** target → **Signing & Capabilities**. Under **Signing**, set **Team** to your Apple ID (e.g. **Personal Team**) or your organization’s team. You can add your Apple ID under **Xcode → Settings → Accounts** if needed.

- **"A build only device cannot be used to run this target"**  
  The run destination is set to **Any iOS Device**, which is for building only. In the toolbar, click the device menu next to the Run button and choose an **iPhone simulator** (e.g. iPhone 16). See also **RUN_ON_SIMULATOR.md**.

## Item 9 — Picture to describe

For **item 9 (Best Language)**, the app shows **objects to name** (watch, pencil) and a **picture to describe**. The object icons use system graphics. The “picture to describe” uses the image set **Item9_DescribeImage** in `Assets.xcassets`. To use your own image (e.g. a line drawing or scene for the patient to describe), add 1x, 2x, and 3x images to **Item9_DescribeImage.imageset** in Xcode. If no image is added, a placeholder area is still shown.

## Requirements

- Xcode 15 or later (Swift 5, iOS 17).
- iPhone (portrait-oriented; suitable for use at the bedside).

## Project structure

```
NIHSSStrokeScale/
├── NIHSSStrokeScaleApp.swift    # App entry
├── Views/
│   ├── ContentView.swift        # Home: start / continue assessment
│   ├── AssessmentFlowView.swift # Step-by-step flow, next/previous
│   ├── ItemCardView.swift       # One item: Spanish prompt + score buttons
│   └── SummaryView.swift        # Final score and breakdown
├── Models/
│   ├── NIHSSItem.swift         # Item and option types
│   ├── NIHSSData.swift         # All 11 items + Spanish prompts
│   └── AssessmentState.swift   # Scores and total
└── Assets.xcassets
```

## Disclaimer — education only, not for clinical use

**This app is for education and training only. It is not intended for clinical use and must not be used to make or support clinical decisions, diagnoses, or treatment.**

- The app is designed for **learning and practice** of the NIH Stroke Scale and for **educational support** when working with non-English speaking patients in a training context.
- It does **not** replace formal training on the official NIH Stroke Scale or your institution’s stroke protocols.
- It is **not** a medical device and must **not** be relied upon for patient care. Clinical use of the NIH Stroke Scale should follow your facility’s policies, appropriate certifications (e.g. AHA NIHSS training), and applicable law.

**NIH Stroke Scale** is a trademark of the National Institute of Neurological Disorders and Stroke (NINDS). This project is not affiliated with or endorsed by NINDS or NIH.
