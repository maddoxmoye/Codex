#!/usr/bin/env bash
# Fetch only the official Windows x64 export template from Godot's archive.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p godot-native/.templates
python3 - <<'PY'
import hashlib, io, json, pathlib, sys, urllib.request, zipfile

version = '4.6.3'
target = pathlib.Path('godot-native/.templates/windows_release_x86_64.exe')
expected_sha256 = '91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6'
if target.is_file():
    if hashlib.sha256(target.read_bytes()).hexdigest() != expected_sha256:
        raise RuntimeError('Cached Windows template checksum mismatch; remove it and run this installer again')
    print(f'Official Godot {version} Windows template cache verified.')
    sys.exit(0)
release = f'https://api.github.com/repos/godotengine/godot-builds/releases/tags/{version}-stable'
headers = {'User-Agent': 'Wildfall-native-build', 'Accept-Encoding': 'identity'}
with urllib.request.urlopen(urllib.request.Request(release, headers=headers), timeout=60) as response:
    metadata = json.load(response)
asset = next(a for a in metadata['assets'] if a['name'] == f'Godot_v{version}-stable_export_templates.tpz')
url, size = asset['browser_download_url'], asset['size']

class RemoteArchive(io.RawIOBase):
    """A seekable ZIP input backed by explicit HTTP ranges, not a full download."""
    def __init__(self):
        self.position = 0
        self.downloaded = 0
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.position
    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else size + offset
        return self.position
    def read(self, count=-1):
        if count < 0: count = size - self.position
        count = min(count, size - self.position)
        if count <= 0: return b''
        end = self.position + count - 1
        request = urllib.request.Request(url, headers={**headers, 'Range': f'bytes={self.position}-{end}'})
        with urllib.request.urlopen(request, timeout=180) as response:
            if response.status != 206:
                raise RuntimeError('Server did not honor the requested byte range')
            expected = f'bytes {self.position}-{end}/{size}'
            if response.headers.get('Content-Range') != expected:
                raise RuntimeError('Export template range did not match its release metadata')
            result = response.read()
        if len(result) != count: raise RuntimeError('Incomplete template download')
        self.position += count
        self.downloaded += count
        return result

remote = RemoteArchive()
with zipfile.ZipFile(remote) as archive:
    entry = archive.getinfo('templates/windows_release_x86_64.exe')
    print(f'Fetching official Godot {version} Windows template ({entry.compress_size / 1024 / 1024:.1f} MB range).', flush=True)
    data = archive.read(entry)  # zipfile verifies the archive entry CRC.
if hashlib.sha256(data).hexdigest() != expected_sha256:
    raise RuntimeError('Downloaded Windows template checksum did not match Godot 4.6.3')
if data[:2] != b'MZ': raise RuntimeError('Expected Windows PE template')
temporary = target.with_suffix('.download')
temporary.write_bytes(data)
temporary.replace(target)
print(f'Cached {target} ({len(data) / 1024 / 1024:.1f} MB); downloaded {remote.downloaded / 1024 / 1024:.1f} MB of the archive.')
PY
