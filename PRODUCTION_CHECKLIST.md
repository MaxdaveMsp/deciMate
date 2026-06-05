# deciMate Production Checklist

## Before App Store submission
- Replace provisional SPL conversion with validated calibration workflow and per-device testing.
- Implement true A/C/Z weighting filters or clearly label weighting as approximate until validated.
- Add ShareLink / document exporter for CSV and PDF reports.
- Add persistent storage for sessions and calibration profiles.
- Add onboarding explaining measurement limitations and microphone permission.
- Add app icon, screenshots, privacy nutrition labels, and App Store copy.
- Test on real iPhones with at least one reference SPL meter and one acoustic calibrator.
- Verify iOS background/lock-screen behavior for long logging sessions.
- Decide Basic vs Pro monetization: paid app, in-app purchase, or separate Pro unlock.

## deciMate Live Link Pro
- Define REST endpoints: /status, /session, /thresholds, /events, /export.csv.
- Define WebSocket live payload schema.
- Define OSC addresses: /decimate/spl/current, /decimate/spl/average, /decimate/state.
- Add LAN-only security defaults and explicit user start/stop control.
- Create Max/MSP and TouchDesigner example clients.
- Research direct possibilities/limitations for SMAART and RiTA ingest workflows.
