#!/usr/bin/env python3
"""Compress MIDI samples as SF3 for the web build (shared KYS-CPP conversion)."""
from concurrent.futures import ThreadPoolExecutor
import io
import struct

import numpy as np
import soundfile as sf


VORBIS_QUALITY = 4
SAMPLE_HEADER = struct.Struct('<20sIIIIIBbHH')


def chunks(data):
    position = 0
    while position < len(data):
        if position + 8 > len(data):
            raise ValueError('Truncated RIFF chunk header')
        tag, size = struct.unpack_from('<4sI', data, position)
        end = position + 8 + size
        if end > len(data):
            raise ValueError(f'Truncated RIFF chunk: {tag!r}')
        yield tag, data[position + 8:end]
        position = end + size % 2


def chunk(tag, data, *, pad=True):
    return tag + struct.pack('<I', len(data)) + data + (b'\0' if pad and len(data) % 2 else b'')


def convert_sf2(original):
    if original[:4] != b'RIFF' or original[8:12] != b'sfbk':
        raise ValueError('Input must be an SF2 SoundFont')
    top = list(chunks(original[12:]))
    lists = {data[:4]: list(chunks(data[4:])) for tag, data in top if tag == b'LIST'}
    if struct.unpack('<HH', dict(lists[b'INFO'])[b'ifil'])[0] != 2:
        raise ValueError('Input must be SF2, not an already compressed SoundFont')
    sample_chunks = dict(lists[b'sdta'])
    if b'sm24' in sample_chunks:
        raise ValueError('24-bit SF2 samples are not supported by this converter')
    pcm = sample_chunks[b'smpl']
    shdr = dict(lists[b'pdta'])[b'shdr']
    if len(shdr) < SAMPLE_HEADER.size or len(shdr) % SAMPLE_HEADER.size:
        raise ValueError('Invalid SF2 sample header table')
    headers = [list(values) for values in SAMPLE_HEADER.iter_unpack(shdr[:-SAMPLE_HEADER.size])]

    def encode(header):
        if header[9] & (0x8000 | 0x10):
            raise ValueError('ROM or already compressed samples are not supported')
        start, end = header[1:3]
        if not 0 <= start < end <= len(pcm) // 2:
            raise ValueError(f'Invalid SF2 sample range: {header[0]!r}')
        samples = np.frombuffer(pcm[start * 2:end * 2], dtype='<i2').astype(np.int16, copy=False)
        stream = io.BytesIO()
        with sf.SoundFile(stream, 'w', samplerate=header[5], channels=1,
                          format='OGG', subtype='VORBIS',
                          compression_level=1.0 - VORBIS_QUALITY / 10) as encoder:
            encoder.write(samples)
        return stream.getvalue()

    with ThreadPoolExecutor(max_workers=4) as pool:
        streams = list(pool.map(encode, headers))
    encoded_headers = []
    position = 0
    for header, stream in zip(headers, streams):
        converted = header.copy()
        # FluidSynth subtracts one from SHDR end before decoding the byte range.
        converted[1:3] = position, position + len(stream)
        converted[3:5] = header[3] - header[1], header[4] - header[1]
        converted[9] |= 0x10
        encoded_headers.append(SAMPLE_HEADER.pack(*converted))
        position += len(stream)
    replacements = {
        (b'INFO', b'ifil'): struct.pack('<HH', 3, 0),
        (b'sdta', b'smpl'): b''.join(streams),
        (b'pdta', b'shdr'): b''.join(encoded_headers) + shdr[-SAMPLE_HEADER.size:],
    }
    result = b'sfbk'
    for tag, data in top:
        if tag == b'LIST':
            name = data[:4]
            body = b''.join(chunk(child_tag, replacements.get((name, child_tag), child_data),
                                  pad=name != b'sdta')
                            for child_tag, child_data in lists[name])
            # SF3's compressed sample data and enclosing LIST are not padded.
            result += chunk(tag, name + body, pad=name != b'sdta')
        else:
            result += chunk(tag, data)
    return chunk(b'RIFF', result, pad=False)

