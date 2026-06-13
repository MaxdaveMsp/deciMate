# DeciMate SPL Live Link examples

These examples show how to receive DeciMate SPL Live Link Pro data on a machine on the same local network as the iPhone.

## Live Link endpoint

When Live Link is enabled in DeciMate SPL, the app shows the exact local addresses available on the iPhone. Use the IP address shown in Settings first:

```text
http://192.168.1.42:8080/status
```

`iphone.local` is still listed as a fallback, but many networks do not resolve it reliably. The app exposes two HTTP endpoints:

```text
/status  One JSON snapshot per request
/stream  Continuous server-sent events with one JSON snapshot every 0.5 seconds
```

The app currently returns a JSON payload like this:

```json
{
  "app": "DeciMate SPL",
  "timestamp": "2026-06-12T20:15:30Z",
  "spl_current": 84.2,
  "spl_average": 81.7,
  "spl_peak": 96.4,
  "spl_leq": 83.6,
  "leq_1_minute": 84.8,
  "leq_10_minutes": 82.9,
  "osha_dose_percent": 3.2,
  "niosh_dose_percent": 8.7,
  "eu_lex8h": 61.4,
  "weighting": "A",
  "response": "Fast",
  "measurement_mode": "SPL A Fast",
  "threshold_state": "safe",
  "companion_state": "All good!"
}
```

## OSC stream

DeciMate SPL can also send the same live readings as OSC over UDP.

In DeciMate SPL:

1. Open Settings.
2. Start Live Link.
3. Turn on Stream OSC.
4. Set OSC host to your dashboard computer IP address, for example `192.168.1.20`.
5. Set OSC port to the port your receiving app listens on, for example `9000`.

The default host is `255.255.255.255`, which attempts a local-network broadcast. A direct computer IP is more reliable because some Wi-Fi routers block broadcast UDP.

OSC addresses:

```text
/decimate/spl/current
/decimate/spl/average
/decimate/spl/peak
/decimate/spl/leq
/decimate/spl/leq1m
/decimate/spl/leq10m
/decimate/exposure/oshaDose
/decimate/exposure/nioshDose
/decimate/exposure/euLex8h
/decimate/mode/weighting
/decimate/mode/response
/decimate/mode/measurement
/decimate/state/threshold
/decimate/state/companion
```

To test OSC without another app, run the included receiver:

```sh
node examples/live-link/osc-receiver/live-link-osc-receiver.mjs
```

Then set DeciMate SPL's OSC host to your computer IP and OSC port to `9000`. To listen on a different port:

```sh
node examples/live-link/osc-receiver/live-link-osc-receiver.mjs 9001
```

## Before running an example

1. Put the iPhone and dashboard machine on the same Wi-Fi network.
2. Open DeciMate SPL on the iPhone.
3. Start monitoring.
4. Enable Live Link in DeciMate SPL.
5. Open one of the examples below.

If the examples cannot connect, confirm that iOS granted DeciMate SPL local-network permission, keep the iPhone awake with DeciMate SPL in the foreground, and use the numeric IP address shown by the app.

## Examples

### 1. Simple browser dashboard

Open:

```text
examples/live-link/simple-dashboard/index.html
```

This is the smallest practical dashboard. It polls Live Link once per second and updates current, average, peak, and state values.

### 2. Animated DeciMate SPL dashboard

Open:

```text
examples/live-link/animated-dashboard/index.html
```

This version includes a DeciMate SPL-style animated companion, sound bars, state colors, and a larger meter view.

### 3. Node logger

Run:

```sh
node examples/live-link/node-logger/live-link-logger.mjs
```

To use a specific endpoint:

```sh
node examples/live-link/node-logger/live-link-logger.mjs http://192.168.1.42:8080/status
```

This logs readings in the terminal and writes `decimate-live-link-log.csv` in the current directory.

## Mock mode

The browser dashboards include mock mode buttons so you can test layout and animations before connecting to the iPhone.

For the Node logger:

```sh
node examples/live-link/node-logger/live-link-logger.mjs --mock
```
