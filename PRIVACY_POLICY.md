# Privacy Policy — Qibla Time

**Last updated:** August 3, 2026
**Effective date:** July 15, 2026

---

## 1. Overview

Qibla Time ("the App", "we", "our") is developed and maintained by an individual developer based in Spain and is therefore subject to the **General Data Protection Regulation (GDPR)** (EU) 2016/679.

This Privacy Policy explains what information the App accesses, how it is used, when online features may contact external services, and your rights as a user. The short version: **Qibla Time has no ads, no analytics, no tracking SDKs, and we do not sell personal information.**

---

## 2. Data We Do Not Collect

Qibla Time does **not**:

- Use advertising networks or display advertisements of any kind
- Use analytics SDKs (no Firebase, no Google Analytics, no Mixpanel, etc.)
- Require account registration or login
- Track your behavior across apps or websites
- Sell personal information
- Share any data with third parties for marketing or profiling purposes

Some optional or content-related features use external services to load religious content, audio, book metadata, store links, or system geocoding results. These are described below.

---

## 3. Location Data

The App requests access to your device's **GPS / network location** for the purpose of:

- Calculating the five daily Islamic prayer times (Fajr, Dhuhr, Asr, Maghrib, Isha) based on your geographic coordinates
- Determining the Qibla direction (the bearing toward Mecca) from your current position
- Finding nearby mosques, halal restaurants, and halal butchers when you choose to use the nearby places feature

**Your location coordinates are:**
- Used by the App to calculate prayer times and Qibla direction
- Stored locally when needed so the App can keep working without asking for GPS every time
- Not sold, used for advertising, or used for analytics

Most prayer time and Qibla calculations are performed on-device using the open-source [Adhan](https://github.com/batoulapps/adhan-dart) library. If you search for or save a manual city, the device's geocoding service may be used to convert the city name into coordinates. If the App displays a readable place name for coordinates, the device's reverse geocoding service may be used. These geocoding services are provided by the operating system or platform provider.

When you use the nearby places feature, the App may send the coordinates of your current location or manually selected city and the selected search radius to Geoapify or public Overpass/OpenStreetMap services. Geoapify is used to find halal restaurants and butchers, while Overpass/OpenStreetMap is used for mosques and as a fallback. Qibla Time does not operate its own server for these searches and does not store those searches on a Qibla Time server. Nearby results may be cached locally on your device for approximately 12 hours to reduce repeated requests. Data availability and accuracy depend on the external providers and OpenStreetMap contributors.

You can revoke location permission at any time through your device's system settings. The App can fall back to a manually entered or last-saved location where available.

---

## 4. Locally Stored Data

User preferences and saved content are stored in your device's **local storage** (using Android SharedPreferences / iOS UserDefaults and local app storage). This includes:

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

This local data is not uploaded by us to our own servers. Some online features may separately contact external services as described below.

---

## 5. Third-Party Services

### 5.1 Quran Text APIs

The Quran reader may contact Quran content APIs, including Quran.com and AlQuran Cloud, to load Quran text, translations, transliteration, and Tajweed data. These requests generally include the surah, ayah, language, or resource being requested. As with any internet request, the external service may receive technical information such as your IP address, device network metadata, and request time.

### 5.2 Quran Audio Files

Quran recitation audio files may be streamed or downloaded from publicly available audio hosts/CDNs such as EveryAyah.com mirrors. Audio may be cached locally on your device for playback or offline use.

### 5.3 IslamHouse API

The App fetches **Islamic books and educational content** from the [IslamHouse.com](https://islamhouse.com) public API. This is used to retrieve book lists, metadata, covers, and downloadable or readable book files. IslamHouse's own privacy policy applies to their servers.

### 5.4 Tafsir

Tafsir is an online feature when available. The App may contact Quran.com or QUL/Tarteel services to request Tafsir for a specific surah and ayah, resource, and language.

### 5.5 Word-by-Word Quran

Word-by-Word Quran support is currently feature-flagged and may use Quran.com APIs when enabled. Results may be cached temporarily on the device.

### 5.6 Geocoding Services

When you search for a manual city or when the App converts coordinates into a readable city/country label, the App may use the geocoding service provided by your device platform. This may send the typed place name or coordinates to the platform provider.

### 5.7 App Stores and Contact Links

When you choose to rate, share, or open the store listing, the App opens Google Play or the Apple App Store. When you choose to contact support, the App opens your email client with a support email draft. These actions are initiated by you.

### 5.8 Geoapify and OpenStreetMap / Overpass

The nearby places feature uses Geoapify and OpenStreetMap data through Geoapify and public Overpass API endpoints. Requests include the coordinates and search radius needed to find nearby mosques, halal restaurants, or halal butchers. Geoapify and OpenStreetMap's own terms and privacy practices apply to requests handled by their services.

### 5.9 Google Play and App Store

The App may be distributed through Google Play and the Apple App Store. Google and Apple may collect installation, purchase, crash, or store analytics data according to their own privacy policies. This data is collected by the store provider, not directly by us.

---

## 6. Permissions

| Permission | Why it is needed |
|---|---|
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Calculate prayer times and Qibla direction |
| `INTERNET` | Load online Quran content, Quran audio, IslamHouse content, optional Tafsir, nearby places data, store links, and other online features |
| `RECEIVE_BOOT_COMPLETED` | Reschedule local prayer time notifications after device reboot |
| `SCHEDULE_EXACT_ALARM` | Deliver prayer time notifications at precise times |
| `VIBRATE` | Optional notification vibration |

No permission is used for any purpose other than what is stated above.

---

## 7. Children's Privacy

The App does not knowingly collect personal information from children. Some online content features may contact the external services described above.

---

## 8. Your Rights Under GDPR

Because the developer is based in Spain (EU), the following GDPR rights apply to you regardless of your country of residence:

- **Right of access** — You have the right to know what personal data we hold about you. We do not maintain user accounts or personal data databases.
- **Right to erasure ("right to be forgotten")** — You may delete all locally stored app data at any time by clearing the App's storage in your device settings or by uninstalling the App.
- **Right to data portability** — Not applicable to us because we do not maintain a server-side user profile.
- **Right to object** — You can avoid optional online features or revoke permissions through your device settings.
- **Right to lodge a complaint** — If you believe your privacy rights have been violated, you may lodge a complaint with the Spanish data protection authority, the **Agencia Española de Protección de Datos (AEPD)** at [aepd.es](https://www.aepd.es), or the supervisory authority of your country of residence.

---

## 9. Data Retention

We do not operate a server that stores Qibla Time user profiles or personal data. Locally stored preferences, cached content, and downloaded files remain on your device until you clear them or uninstall the App. External services contacted by online features may have their own retention practices.

---

## 10. Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be reflected by updating the "Last updated" date at the top of this document. The current version is available in the App's settings screen and/or store listing.

---

## 11. Contact

If you have any questions or concerns about this Privacy Policy, please contact:

**Developer:** Said (individual developer, Spain)
**Email:** support.qiblatime@gmail.com
**Google Play:** [Qibla Time on Google Play](https://play.google.com/store/apps/details?id=com.qiblatime.mobile)
**App Store:** [Qibla Time on the App Store](https://apps.apple.com/es/app/qibla-time/id6771987364)

---

*This privacy policy was written in plain language with the intent of being fully transparent. Qibla Time is built for the community, not for advertising, tracking, or data sales.*
