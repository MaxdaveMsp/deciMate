# DeciMate SPL examples

This folder contains examples for receiving DeciMate SPL Live Link Pro data on a computer on the same local network as the iPhone.

## Before you start

1. Put the iPhone and computer on the same Wi-Fi network.
2. Open DeciMate SPL on the iPhone.
3. Start monitoring.
4. Open Settings.
5. Tap Start Live Link.
6. If iOS asks for Local Network permission, allow it.

Use the numeric address shown by DeciMate SPL first, for example:

```text
http://192.168.1.42:8080/status
```

`iphone.local` can work on some networks, but the numeric IP address is usually more reliable.

## JSON dashboard examples

DeciMate SPL exposes two local HTTP endpoints:

```text
/status  One JSON snapshot per request
/stream  Continuous live JSON updates
```

### Simple dashboard

Open this file in a browser:

```text
examples/live-link/simple-dashboard/index.html
```

Paste the `/status` URL shown in DeciMate SPL, then connect. This dashboard is good for confirming that the phone and computer can talk to each other.

### Animated dashboard

Open this file in a browser:

```text
examples/live-link/animated-dashboard/index.html
```

Paste the same `/status` URL. This version includes the DeciMate SPL-style animated display and is better for live monitoring demos.

### Terminal logger

Run:

```sh
node examples/live-link/node-logger/live-link-logger.mjs http://192.168.1.42:8080/status
```

Replace the IP address with the one shown in DeciMate SPL. The logger prints readings in Terminal and writes a CSV log.

## OSC example

DeciMate SPL can also send live readings as OSC over UDP.

Run the included OSC receiver:

```sh
node examples/live-link/osc-receiver/live-link-osc-receiver.mjs
```

Then in DeciMate SPL Settings:

1. Turn on Stream OSC.
2. Set OSC host to your computer IP address.
3. Set OSC port to `9000`.

The receiver will print OSC messages such as:

```text
/decimate/spl/current
/decimate/spl/average
/decimate/spl/peak
/decimate/spl/leq
/decimate/state/threshold
```

To listen on a different OSC port:

```sh
node examples/live-link/osc-receiver/live-link-osc-receiver.mjs 9001
```

Then set the same port in DeciMate SPL.

## Troubleshooting

- Keep DeciMate SPL open in the foreground while testing.
- Make sure the iPhone and computer are on the same Wi-Fi network.
- Use the numeric IP address shown in DeciMate SPL instead of `iphone.local`.
- If the browser cannot connect, stop and start Live Link again.
- If OSC does not arrive, set OSC host directly to the computer IP instead of using `255.255.255.255`.

More details are available in:

```text
examples/live-link/README.md
```
