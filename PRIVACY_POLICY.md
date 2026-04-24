# Privacy Policy — QiblaTime

**Last updated:** April 12, 2026
**Effective date:** April 12, 2026

---

## 1. Overview

QiblaTime ("the App", "we", "our") is developed and maintained by an individual developer based in Spain and is therefore subject to the **General Data Protection Regulation (GDPR)** (EU) 2016/679.

This Privacy Policy explains what information the App accesses, how it is used, and your rights as a user. The short version: **we collect nothing. All data stays on your device.**

---

## 2. Data We Do Not Collect

QiblaTime does **not**:

- Collect, store, or transmit any personally identifiable information (PII)
- Use advertising networks or display advertisements of any kind
- Use analytics SDKs (no Firebase, no Google Analytics, no Mixpanel, etc.)
- Require account registration or login
- Track your behavior across apps or websites
- Share any data with third parties for marketing or profiling purposes

---

## 3. Location Data

The App requests access to your device's **GPS / network location** for the sole purpose of:

- Calculating the five daily Islamic prayer times (Fajr, Dhuhr, Asr, Maghrib, Isha) based on your geographic coordinates
- Determining the Qibla direction (the bearing toward Mecca) from your current position

**Your location coordinates are:**
- Processed entirely **on-device** using the open-source [Adhan](https://github.com/batoulapps/adhan-dart) library
- **Never transmitted** to any server, API, or third-party service
- **Never stored** beyond the current app session (unless you choose to save a manual location in the App's settings, in which case it is stored locally on your device only)

You can revoke location permission at any time through your device's system settings. The App will fall back to a manually entered or last-saved location.

---

## 4. Locally Stored Data

All user preferences and content saved by the App are stored exclusively in your device's **local storage** (using Android SharedPreferences / iOS UserDefaults). This includes:

| Data | Purpose |
|---|---|
| Saved location coordinates | Calculate prayer times without GPS each launch |
| Prayer calculation method preference | User-selected calculation school |
| Active language / locale | UI language preference |
| Notification settings | Local prayer time alarms |
| Quran recitation progress | Bookmark and last-played position |
| Dua favorites and custom notes | User-curated content |
| Period mode setting | Menstruation tracking toggle (salah reminder behavior) |
| Onboarding completion flag | Skip intro on subsequent launches |

None of this data leaves your device.

---

## 5. Third-Party Services

### 5.1 IslamHouse API

The App fetches **Islamic books and educational content** (Hadith collections, Dua booklets) from the [IslamHouse.com](https://islamhouse.com) public API. This is a read-only request to retrieve content; no user data is sent as part of this request. The only information transmitted is a standard HTTP request (your IP address is visible to IslamHouse's servers as is the case with any HTTP connection). IslamHouse's own privacy policy applies to their servers.

### 5.2 Quran Audio Files

Quran recitation audio files are downloaded from publicly available CDN URLs (e.g., EveryAyah.com mirrors) upon first playback and then cached locally on your device. No user-identifying data is sent alongside these requests.

### 5.3 Google Play

The App is distributed through the Google Play Store. Google collects installation and crash data according to [Google's Privacy Policy](https://policies.google.com/privacy). This data is collected by Google, not by us, and we receive only aggregated, anonymised crash reports through the Play Console.

---

## 6. Permissions

| Permission | Why it is needed |
|---|---|
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Calculate prayer times and Qibla direction |
| `INTERNET` | Download Quran audio files and IslamHouse content |
| `RECEIVE_BOOT_COMPLETED` | Reschedule local prayer time notifications after device reboot |
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Deliver prayer time notifications at precise times |
| `VIBRATE` | Optional notification vibration |
| `READ_EXTERNAL_STORAGE` (optional) | Access cached audio files on older Android versions |

No permission is used for any purpose other than what is stated above.

---

## 7. Children's Privacy

The App does not knowingly collect any data from users of any age. Because no personal data is collected at all, the App is safe for use by children.

---

## 8. Your Rights Under GDPR

Because the developer is based in Spain (EU), the following GDPR rights apply to you regardless of your country of residence:

- **Right of access** — You have the right to know what personal data we hold about you. In our case: none.
- **Right to erasure ("right to be forgotten")** — You may delete all locally stored app data at any time by clearing the App's storage in your device settings or by uninstalling the App.
- **Right to data portability** — Not applicable; no data is collected.
- **Right to object** — Not applicable; no data is processed.
- **Right to lodge a complaint** — If you believe your privacy rights have been violated, you may lodge a complaint with the Spanish data protection authority, the **Agencia Española de Protección de Datos (AEPD)** at [aepd.es](https://www.aepd.es), or the supervisory authority of your country of residence.

---

## 9. Data Retention

We retain **no data** on any server. Locally stored preferences and cached files remain on your device until you clear them or uninstall the App.

---

## 10. Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be reflected by updating the "Last updated" date at the top of this document. The current version is always available in the App's settings screen and in the App's Google Play listing.

---

## 11. Contact

If you have any questions or concerns about this Privacy Policy, please contact:

**Developer:** Said (individual developer, Spain)
**Email:** contact@qiblatime.app
**Google Play:** [QiblaTime on Google Play](https://play.google.com/store/apps/details?id=com.qiblatime.mobile)

---

*This privacy policy was written in plain language with the intent of being fully transparent. QiblaTime is built for the community, not for data collection.*
