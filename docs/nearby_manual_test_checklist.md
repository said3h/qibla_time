# Nearby Places Manual Test Checklist

Use this checklist to test the first Nearby Places release on real Android and iOS devices.

## City Manual

- Select Benidorm manually, open Nearby Places, then Mosques. Expected: no GPS prompt, mosque list loads or a clear empty/error state appears.
- Select Altea manually, open Mosques. Expected: origin changes and cached Benidorm results are not reused incorrectly.
- Select Alicante manually, open Mosques. Expected: nearby mosques appear when OpenStreetMap has data.
- Switch between Benidorm, Altea, and Alicante. Expected: distance order updates after each city change.
- Test radiuses 5 km, 10 km, 25 km, and 50 km. Expected: larger radiuses do not reuse smaller-radius cache as complete results.

## GPS

- Grant location permission. Expected: Mosques can use device location.
- Deny location permission once. Expected: clear explanation and retry action.
- Deny location permanently from system settings. Expected: no crash, clear unavailable state.
- Turn device GPS off. Expected: app uses cache if available or shows a clear unavailable state.
- Test with only cached location available. Expected: results can load from cached location and debug logs show cached source.
- Tap Retry after restoring location/network. Expected: request runs again and UI updates.

## Results

- Confirm real mosque entries appear in areas with OSM data.
- Confirm ordering is nearest to farthest.
- Confirm churches, synagogues, temples, offices, schools, or unrelated associations do not appear unless OSM tags mark them as Muslim worship/mosque.
- Confirm no obvious duplicate mosque appears from node/way/relation mapping.
- Confirm unnamed mosques show the localized "Unnamed mosque" label.
- Confirm optional fields appear only when present: address, phone, website, opening hours, wheelchair, coordinates.
- Test an area with no known mosques. Expected: localized empty state.
- Enable airplane mode with no cache. Expected: localized error state.
- Enable airplane mode after a successful search. Expected: cached results appear if still valid.
- Close and reopen the app. Expected: cache is reused for the same city/radius within TTL.

## Navigation

- Android with Google Maps installed: tap Directions. Expected: external map opens with the correct destination.
- Android without Google Maps or with multiple map apps: tap Directions. Expected: Android app chooser or compatible map app opens.
- iOS with Apple Maps: tap Directions. Expected: Apple Maps opens with the destination.
- Verify destination name and coordinates in the external map app.
- If no compatible app can open directions, expected: app remains open and shows localized error.

## Interface

- Test light mode and dark mode.
- Test Spanish UI.
- Test Arabic UI and RTL layout.
- Increase system text size. Expected: no clipped key actions.
- Test a small phone screen. Expected: radius selector, cards, and retry buttons remain usable.
- Open Restaurants halal and Halal butchers. Confirm results are sorted by distance, refresh works, and only places explicitly tagged halal in OpenStreetMap appear.
- Confirm OpenStreetMap attribution is visible and opens the OSM copyright page.
