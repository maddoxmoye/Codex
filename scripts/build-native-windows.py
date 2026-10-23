#!/usr/bin/env python3
"""Validate and package the current production game as a portable Windows x64 ZIP."""
import hashlib, json, os, pathlib, shutil, struct, subprocess, zipfile
from datetime import datetime, timezone
ROOT = pathlib.Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'godot-native'
OUT = ROOT / 'dist/native-windows'
BUNDLE = PROJECT / 'exports/windows'
ENV = {**os.environ, 'XDG_CACHE_HOME': '/tmp/wildfall-godot-cache', 'XDG_DATA_HOME': '/tmp/wildfall-godot-data', 'XDG_CONFIG_HOME': '/tmp/wildfall-godot-config'}
def run(args):
    result = subprocess.run(args, cwd=ROOT, env=ENV, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=300)
    print(result.stdout, flush=True)
    if result.returncode or any(term in result.stdout for term in ['SCRIPT ERROR:', 'Parse Error:', 'ERROR:', '_FAILED:']):
        raise RuntimeError(f'Failed: {args}')
    return result.stdout.strip()
OUT.mkdir(parents=True, exist_ok=True)
BUNDLE.mkdir(parents=True, exist_ok=True)
(PROJECT/'exports/.gdignore').write_text('')
run(['node', 'scripts/check-native-demo.mjs'])
run([os.environ.get('GODOT_BIN','godot'), '--headless', '--path', str(PROJECT), '--export-release', 'Windows Desktop', str(BUNDLE/'Wildfall-Emberwood.exe')])
exe=(BUNDLE/'Wildfall-Emberwood.exe').read_bytes()
assert exe[:2]==b'MZ'
pe=struct.unpack_from('<I',exe,0x3c)[0]
assert exe[pe:pe+4]==b'PE\0\0' and struct.unpack_from('<H',exe,pe+4)[0]==0x8664, 'Expected AMD64 Windows executable'
pack=BUNDLE/'Wildfall-Emberwood.pck'
assert pack.stat().st_size>1000000 and pack.read_bytes()[:4]==b'GDPC', 'Missing Godot resource pack'
shutil.copyfile(PROJECT/'WINDOWS_README.md',BUNDLE/'README.txt')
shutil.copytree(PROJECT/'licenses',BUNDLE/'licenses',dirs_exist_ok=True)
archive=OUT/'Wildfall-Emberwood-Windows-x64.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for file in sorted(BUNDLE.rglob('*')):
        if file.is_file():z.write(file, pathlib.Path('Wildfall-Emberwood')/file.relative_to(BUNDLE))
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
sha=hashlib.sha256(archive.read_bytes()).hexdigest()
revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
info={'engine':'Godot 4.6.3','platform':'Windows x86_64','sourceRevision':revision,'builtAt':datetime.now(timezone.utc).isoformat(),'bytes':archive.stat().st_size,'sha256':sha,'automatedSuites':7,'windowsRuntimeTest':'separate CI smoke-test job','gpuPerformanceTested':False,'signed':False}
(OUT/'windows-build-info.json').write_text(json.dumps(info,indent=2)+'\n')
(OUT/'WINDOWS_SHA256SUMS.txt').write_text(f'{sha}  {archive.name}\n')
print('WINDOWS_PACKAGE_OK: AMD64 PE, resource pack, licenses, ZIP CRC and SHA256 verified',flush=True)
