import TSCBasic

let devEntrypointSHA256 = ByteString([
  0x66, 0xD6, 0x8A, 0xF7, 0x1D, 0x05, 0x95, 0x42, 0x84, 0x09, 0x2C, 0x63, 0x7E, 0xC0, 0xD0, 0x42,
  0xA1, 0x5B, 0x9A, 0x95, 0x98, 0x07, 0xCA, 0x7A, 0x05, 0xCB, 0x8C, 0x0B, 0x25, 0x9E, 0xA7, 0xDF,
])

let bundleEntrypointSHA256 = ByteString([
  0xF6, 0x10, 0x78, 0xB2, 0xE4, 0x4A, 0x33, 0xD7, 0x95, 0xCB, 0x25, 0x1E, 0x9F, 0xA7, 0x61, 0xAD,
  0x14, 0x79, 0xC7, 0xC8, 0x31, 0xDE, 0x33, 0xD4, 0x9A, 0xA0, 0xD9, 0x5B, 0xAD, 0xD3, 0xD8, 0x84,
])

let testEntrypointSHA256 = ByteString([
  0xC3, 0x05, 0x93, 0xA9, 0xA7, 0x8B, 0xD7, 0x66, 0x9F, 0xBA, 0x67, 0x68, 0x92, 0xCA, 0x87, 0x41,
  0x88, 0x2E, 0xCC, 0x2C, 0x5A, 0xA5, 0xE2, 0xB6, 0x9C, 0x09, 0xD4, 0x55, 0xE2, 0x0C, 0x27, 0x08,
])

let staticArchiveHash = ByteString([
  0xD2, 0xA1, 0x3E, 0xF7, 0xF9, 0xCF, 0xFD, 0xBC, 0x77, 0x71, 0xB5, 0xC9, 0x05, 0x1B, 0x8E, 0x16,
  0x06, 0xD3, 0x1B, 0x8F, 0xBC, 0x06, 0xB5, 0x7F, 0xED, 0x43, 0x27, 0x5A, 0x5E, 0xD5, 0xB0, 0x37,
])
