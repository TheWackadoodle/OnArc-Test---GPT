# Daywell
**Short description**: See your whole day on one dial, on your phone and Wear OS watch.

**Full description**: Lay out your day as coloured arcs on a 24-hour dial. Start with a sample day, move and resize its arcs, or clear it and build your own. Today shows the current activity, the minutes left and what comes next. On Wear OS, glance at your agenda, open the current arc in focus view, or add the tile and watch-face complication. Start nudges and alarm sounds are optional. Transfer a dial to your paired watch over Bluetooth and keep a local JSON backup.

## Play Console draft
Phone and Wear OS use the same package with distinct version codes. App is free. No ads, purchases, accounts or server. Data Safety draft: no developer collection or sharing. Permissions include paired-device access, optional notifications, exact-alarm special access, vibration and boot rescheduling. Complete the publisher identity, support contact, privacy policy URL, audience and rating questionnaire in the owner's console. Verify declarations against both signed merged manifests and device behavior before submission.

## Release gates
1. Build and install both signed APKs. Inspect permissions in both APKs. Verify release bundles with bundletool. Inspect the encrypted signing backup by checking its certificate fingerprint.
2. On phone, exercise onboarding, empty and sample dials, all editor gestures, endpoint adjacency and rejected overlap. Test malformed and oversized backup import, cancelled pickers and JSON round trip. Verify deletion survives reopening. Repeat at largest font scale.
3. Pair actual devices. Test successful transfer, wrong peer, disconnect, invalid payload, timeout and retry. Confirm watch plan still works away from phone. Verify launch, focus, tile, complication, and independent buzzes on a round screen.
4. With notifications off, verify silence. Enable nudges, grant exact timing, test screen off, consecutive short arcs, reboot, permission revocation, time changes, travel and DST. Confirm no duplicate heads-up when both devices are worn. Measure delivery latency, including Doze restrictions.
5. Capture real phone Today, editor, templates and settings screens plus watch agenda, focus, tile and complication. Supply actual device screenshots to the listing.
6. Use a closed test and daily use to find and repair defects. Confirm current eligibility in Play Console. Submit production only after the owner approves the tested release.
