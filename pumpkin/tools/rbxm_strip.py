"""Drop named properties from a binary .rbxm/.rbxl (LZ4 or uncompressed chunks); rewrite all chunks uncompressed."""
import struct, sys

def lz4_block_decompress(src, usize):
    dst = bytearray(); i = 0; n = len(src)
    while i < n:
        token = src[i]; i += 1
        lit = token >> 4
        if lit == 15:
            while True:
                b = src[i]; i += 1; lit += b
                if b != 255: break
        dst += src[i:i+lit]; i += lit
        if i >= n: break
        off = src[i] | (src[i+1] << 8); i += 2
        ml = token & 15
        if ml == 15:
            while True:
                b = src[i]; i += 1; ml += b
                if b != 255: break
        ml += 4
        start = len(dst) - off
        for k in range(ml): dst.append(dst[start + k])
    assert len(dst) == usize, (len(dst), usize)
    return bytes(dst)

def main(inp, out, drop):
    data = open(inp, 'rb').read()
    head = data[:32]; p = 32; chunks = []; dropped = {}
    while p < len(data):
        name = data[p:p+4]; clen, ulen, _ = struct.unpack('<III', data[p+4:p+16]); p += 16
        raw = data[p:p+(clen or ulen)]; p += (clen or ulen)
        if clen:
            if raw[:4] == b'\x28\xb5\x2f\xfd': raise SystemExit('zstd chunk not supported')
            body = lz4_block_decompress(raw, ulen)
        else:
            body = raw
        if name == b'PROP':
            cls, nl = struct.unpack('<II', body[:8]); pname = body[8:8+nl].decode()
            if pname in drop:
                dropped[pname] = dropped.get(pname, 0) + 1
                continue
        chunks.append((name, body))
        if name == b'END\x00': break
    with open(out, 'wb') as f:
        f.write(head)
        for name, body in chunks:
            f.write(name + struct.pack('<III', 0, len(body), 0) + body)
    print('dropped', dropped)

def props(inp):
    data = open(inp, 'rb').read(); p = 32; seen = set()
    while p < len(data):
        name = data[p:p+4]; clen, ulen, _ = struct.unpack('<III', data[p+4:p+16]); p += 16
        raw = data[p:p+(clen or ulen)]; p += (clen or ulen)
        body = lz4_block_decompress(raw, ulen) if clen else raw
        if name == b'PROP':
            nl = struct.unpack('<I', body[4:8])[0]; seen.add(body[8:8+nl].decode())
        if name == b'END\x00': break
    print(sorted(seen))

if __name__ == '__main__':
    if sys.argv[1] == 'props': props(sys.argv[2])
    else: main(sys.argv[1], sys.argv[2], set(sys.argv[3].split(',')))
