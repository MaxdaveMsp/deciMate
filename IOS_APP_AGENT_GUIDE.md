# iOS App Agent Guide

Use this document when asking an agent to design, implement, build, archive, and prepare a native iOS app for TestFlight or App Store submission.

## Goal

Give the agent enough structure to:

- understand the app idea
- choose the right iOS architecture
- build and archive in Xcode
- prepare the app for App Store Connect
- avoid the common iOS submission mistakes

## How To Use This With An Agent

Start your request with:

```text
Use IOS_APP_AGENT_GUIDE.md as the implementation contract for this app.
```

Then provide:

1. App idea
2. Main user flow
3. Whether background audio/video is needed
4. Whether the app is local-network only or internet-facing
5. Whether it must be ready for App Store submission now

## Required Agent Output

The agent should deliver:

- a native iOS project
- exact Xcode build/archive steps
- correct app version and build number handling
- icon and launch screen configured
- signing prerequisites clearly stated
- App Store submission/readiness notes

## Preferred iOS Direction

Default to **native iOS** when any of these are true:

- background audio matters
- lock-screen behavior matters
- WebRTC / LiveKit / low-latency media is involved
- AVAudioSession behavior matters
- App Store submission quality matters

Do **not** default to WebView or Expo-style wrappers for production iOS if reliable media behavior is a core requirement.

## Ask The Agent To Clarify These Early

The agent should confirm:

- app name
- bundle identifier
- Apple team / signing ownership
- whether background audio is needed
- whether local-network `http://` support is needed
- whether QR scanning is needed
- whether release to TestFlight/App Store is required now
- whether the app is for public content or authorized private/event content

## Architecture Rules

### 1. Native First

Prefer:

- Swift
- SwiftUI for UI unless there is a strong UIKit reason
- proper `AVAudioSession` configuration for media apps
- native camera/QR support if scanning is required

### 2. Local Network / HTTP Support

If the app must work on a private local network:

- do not assume HTTPS
- configure transport rules intentionally
- if local `http://` access is required, add the correct App Transport Security exception

### 3. Background Audio

If the app plays live audio:

- use native playback/media frameworks
- configure `AVAudioSession` for playback
- enable `UIBackgroundModes` for audio
- make lock-screen / Now Playing behavior explicit if needed

### 4. QR Scanning

If QR scanning is needed:

- implement camera scanning natively
- include `NSCameraUsageDescription`
- make scanning trigger or prefill the primary join/open flow

## Xcode / Submission Rules The Agent Must Respect

### 1. Versioning

The agent must ensure:

- `MARKETING_VERSION` is the app version
- `CURRENT_PROJECT_VERSION` is the build number
- `Info.plist` uses:
  - `$(MARKETING_VERSION)`
  - `$(CURRENT_PROJECT_VERSION)`

This is critical. If the plist hardcodes version values, archives can keep uploading old versions even when Xcode UI shows new ones.

### 2. Bundle ID

The bundle identifier in the project must match the existing App Store Connect app if one already exists.

If it does not match, Xcode may try to create a new app record instead of uploading to the existing app.

### 3. Launch Screen And Orientation

For App Store validation, the agent must ensure the app has:

- a launch storyboard or equivalent launch configuration
- supported interface orientations set intentionally

### 4. Encryption Compliance

To reduce App Store Connect friction, include:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### 5. Store Metadata Risk

If the app handles media, streams, or URLs, the agent must avoid making it look like a generic downloader or unauthorized stream player unless that is truly the intended product.

UI wording matters for review.

## Build / Archive Expectations

The agent should provide:

- how to open the project in Xcode
- how to select signing
- how to archive
- how to upload to App Store Connect

Typical flow:

1. Open `.xcodeproj` or `.xcworkspace`
2. Select correct scheme
3. Select `Any iOS Device (arm64)`
4. `Product > Archive`
5. `Distribute App`
6. `App Store Connect`
7. `Upload`

## App Review Lessons

Ask the agent to shape the UI and review notes around the real use case.

If the app is for:

- live conference interpretation
- translation channels
- private event audio
- local-network tools

then the app should say that clearly.

Avoid generic wording like:

- “open any stream”
- “play any audio URL”
- anything that makes the app look like a public media access tool

If the app only plays authorized private/event content, the app and review notes should say so explicitly.

## iOS-Specific Checklist

Before calling the work done, the agent should check:

- app builds in Xcode
- scheme exists and can archive
- bundle id matches intended App Store app
- version/build values archive correctly
- icon appears correctly
- launch screen appears correctly
- background audio settings are present if needed
- camera usage description exists if QR scanning is used
- encryption compliance key is present if appropriate

## Suggested Prompt Template

Use this when briefing an agent:

```text
Use IOS_APP_AGENT_GUIDE.md as the implementation contract.

I want a native iOS app with these requirements:
- App name: ...
- Bundle ID: ...
- Main purpose: ...
- Core flow: ...
- Background playback needed: yes/no
- Local network only: yes/no
- QR scanning needed: yes/no
- Must be App Store ready: yes/no

Please:
- choose the right native iOS architecture
- implement the app
- configure signing-sensitive settings correctly
- set up version/build handling correctly
- configure icon, launch screen, permissions, and metadata
- make it archive-ready in Xcode
- tell me the exact archive/upload steps and any remaining review risks
```
