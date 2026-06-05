# deciMate Deployment Readiness

This file compares the current project against `IOS_APP_AGENT_GUIDE.md`.

## App identity
- App name: deciMate
- Bundle ID: `com.loudandbeyond.decimate`
- Version: `MARKETING_VERSION = 1.0`
- Build: `CURRENT_PROJECT_VERSION = 2`
- iOS minimum: 17.0
- Architecture: native SwiftUI + AVAudioEngine

## Implemented
- Native iOS project with scheme `deciMate`.
- Correct dynamic version/build handling through build settings and Info.plist placeholders.
- Microphone permission text.
- Local-network permission text for deciMate Live Link.
- Encryption compliance key: `ITSAppUsesNonExemptEncryption = false`.
- App icon asset set generated.
- Launch screen storyboard configured.
- SPL monitor UI, calibration offset, thresholds, chart, companion reactions, session model.
- CSV file export via document exporter.
- Basic Live Link local HTTP JSON endpoint prototype.
- Unit tests and simulator build/test verified previously; re-run after each change.

## Still required before App Store upload
- Open in Xcode and set Apple Developer Team signing for the `deciMate` target.
- Confirm whether `com.loudandbeyond.decimate` is the final Bundle ID in App Store Connect.
- Real-device test on iPhone because simulator cannot validate microphone/SPL behavior.
- Validate measurements against a reference SPL meter and/or 94 dB calibrator.
- Decide final wording: must say practical SPL monitoring, not certified compliance measurement.
- Create App Store Connect app record, screenshots, category, support URL, privacy URL.
- Decide monetization: paid app, one-time Pro IAP, or separate Pro unlock.
- Add final privacy policy hosted on GitHub Pages or another public URL.
- Add final support/contact email.
- Optional but recommended: TestFlight beta before App Store review.

## Archive/upload steps
1. Open `/Users/davidtorres/Documents/GitHub/deciMate/deciMate.xcodeproj` in Xcode.
2. Select target `deciMate` > Signing & Capabilities.
3. Select David/Loud and Beyond Apple Developer Team.
4. Confirm Bundle Identifier: `com.loudandbeyond.decimate`.
5. Select scheme `deciMate`.
6. Select destination `Any iOS Device (arm64)`.
7. Product > Archive.
8. Organizer > Distribute App > App Store Connect > Upload.
9. In App Store Connect, attach the uploaded build to TestFlight first.
10. After TestFlight validation, prepare App Review metadata and submit.

## Review notes draft
"deciMate is a practical SPL monitoring and event logging tool for live-event, rehearsal, DJ, and small-venue workflows. It uses the device microphone to estimate sound levels, supports manual calibration against a reference meter, and provides local session logs. It is not marketed as a certified Class 1/Class 2 compliance meter. deciMate Live Link is a local-network feature that only starts when the user explicitly enables it and shares live SPL data with tools on the user's LAN."
