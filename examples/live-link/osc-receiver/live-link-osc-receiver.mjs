import dgram from "node:dgram";

const portArg = process.argv.find((arg) => /^\d+$/.test(arg));
const port = Number(portArg || 9000);
const server = dgram.createSocket("udp4");

function readPaddedString(buffer, offset) {
  let end = offset;
  while (end < buffer.length && buffer[end] !== 0) end += 1;
  const value = buffer.toString("utf8", offset, end);
  const next = Math.ceil((end + 1) / 4) * 4;
  return { value, next };
}

function readMessage(buffer, offset = 0, limit = buffer.length) {
  const address = readPaddedString(buffer, offset);
  const types = readPaddedString(buffer, address.next);
  let cursor = types.next;
  const values = [];

  for (const type of types.value.replace(",", "")) {
    if (type === "f") {
      values.push(Number(buffer.readFloatBE(cursor).toFixed(2)));
      cursor += 4;
    } else if (type === "s") {
      const stringValue = readPaddedString(buffer, cursor);
      values.push(stringValue.value);
      cursor = stringValue.next;
    }
  }

  return {
    address: address.value,
    values,
    next: Math.min(cursor, limit),
  };
}

function readPacket(buffer) {
  if (buffer.subarray(0, 8).toString("utf8") !== "#bundle\u0000") {
    return [readMessage(buffer)];
  }

  const messages = [];
  let cursor = 16;
  while (cursor + 4 <= buffer.length) {
    const size = buffer.readInt32BE(cursor);
    cursor += 4;
    const end = cursor + size;
    if (end > buffer.length) break;
    messages.push(readMessage(buffer, cursor, end));
    cursor = end;
  }
  return messages;
}

server.on("message", (buffer, remote) => {
  const messages = readPacket(buffer);
  const timestamp = new Date().toISOString();
  for (const message of messages) {
    console.log(`${timestamp} ${remote.address}:${remote.port} ${message.address} ${message.values.join(" ")}`);
  }
});

server.on("listening", () => {
  const address = server.address();
  console.log(`Listening for DeciMate SPL OSC on UDP ${address.address}:${address.port}`);
  console.log("In DeciMate SPL Settings, set OSC host to this computer's IP and OSC port to this port.");
});

server.bind(port, "0.0.0.0");
