# How to run the app (fix “build only device” error)

You’re seeing this because the **run destination** is still **“Any iOS Device (arm64)”**. You need to pick an **iPhone simulator** instead.

## Step-by-step

### 1. Find the run destination menu
- Look at the **top center** of the Xcode window (the **toolbar**).
- You’ll see the **scheme** name (e.g. **NIHSSStrokeScale**) and next to it the **destination** (e.g. **“Any iOS Device (arm64)”**).
- **Click that destination** (the part that says “Any iOS Device (arm64)”).  
  It’s the same row as the **Run (▶)** and **Stop (■)** buttons.

### 2. Open the destination list
- A **dropdown menu** opens with two sections:
  - **iOS Device** (or “Destinations”) – often with “Any iOS Device (arm64)” and any connected iPhone.
  - **iOS Simulators** – list of simulators like “iPhone 16”, “iPhone 15”, etc.

### 3. Pick an iPhone simulator
- Under **“iOS Simulators”**, click any **iPhone** (e.g. **iPhone 16**, **iPhone 15**, **iPhone 14**).
- The toolbar will then show that simulator instead of “Any iOS Device (arm64)”.

### 4. Run the app
- Press **Run (▶)** or **⌘R**.  
  The simulator should start and launch the app.

---

## If you don’t see any simulators

1. In the **same destination dropdown**, check for an option like **“Download More Simulators…”** or **“Add Additional Simulators…”**.
2. Or go to **Xcode → Settings** (or **Preferences**) → **Platforms** (or **Components** in older Xcode).
3. Select **iOS** and click the **+** or **Get** to install a simulator runtime (e.g. latest iOS version).
4. After it installs, try the destination dropdown again; new iPhones (e.g. iPhone 16) should appear under **iOS Simulators**.

---

## Alternative: use the menu bar

- **Product → Destination →** then choose any **iPhone** simulator from the list.  
  Same effect as changing the destination in the toolbar.

---

After you select a simulator once, Xcode usually keeps using it until you change it again.
