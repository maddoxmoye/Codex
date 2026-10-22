import {readFile, writeFile, mkdir, stat, copyFile, access} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const project = path.join(root, 'godot-native');
const out = path.join(root, 'dist/native-demo');
const exportsDir = path.join(project, 'exports');
const app = path.join(exportsDir, 'Wildfall Emberwood.app');
const skipChecks = process.argv.includes('--skip-checks');
const landingOnly = process.argv.includes('--landing-only');
const releaseLinks = landingOnly || process.argv.includes('--release-links');
const releaseBase = 'https://github.com/maddoxmoye/Codex/releases/download/emberwood-mac-v0.1.0/';
const exists = async p => access(p).then(() => true, () => false);
const env = {
  ...process.env,
  XDG_CACHE_HOME: process.env.XDG_CACHE_HOME || '/tmp/wildfall-godot-cache',
  XDG_CONFIG_HOME: process.env.XDG_CONFIG_HOME || '/tmp/wildfall-godot-config',
  XDG_DATA_HOME: process.env.XDG_DATA_HOME || '/tmp/wildfall-godot-data',
};
await mkdir(out, {recursive: true});
if (landingOnly) {
  const metadata = JSON.parse(await readFile(path.join(project, 'release-info.json'), 'utf8'));
  await writeLanding(metadata);
  console.log('Built Mac download page with versioned release links.');
  process.exit(0);
}
await mkdir(exportsDir, {recursive: true});
// Godot does not use .gitignore when scanning resources. Never pack an old app into itself.
await writeFile(path.join(exportsDir, '.gdignore'), '');
if (!await exists(path.join(project, '.templates/macos.zip'))) {
  throw new Error('Missing official macOS template. Run bash scripts/install-godot-native.sh first.');
}
if (!skipChecks && !await exists(path.join(project, 'check_native.gd'))) {
  throw new Error('Native integration validation is not ready: godot-native/check_native.gd is required.');
}
function run(binary, args, extra = {}) {
  const result = spawnSync(binary, args, {cwd: root, env, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, ...extra});
  process.stdout.write(result.stdout || '');
  process.stderr.write(result.stderr || '');
  if (result.error || result.status !== 0 || /SCRIPT ERROR:|Parse Error:|\bERROR:|Failed to export project|_FAILED:/.test((result.stdout || '') + (result.stderr || ''))) {
    throw result.error || new Error(`${binary} failed (${result.status}): ${args.join(' ')}`);
  }
  return result.stdout || '';
}
const godot = process.env.GODOT_BIN || 'godot';
run(godot, ['--headless', '--path', project, '--editor', '--import']);
const checks = [];
if (!skipChecks) {
  for (const name of ['check_hunt.gd', 'check_animation.gd', 'check_run.gd', 'check_motion.gd', 'check_hud.gd', 'check_native.gd', 'check_campaign.gd']) {
    if (!await exists(path.join(project, name))) continue;
    run(godot, ['--headless', '--path', project, '--script', name]);
    checks.push(name);
  }
}
run(godot, ['--headless', '--path', project, '--export-release', 'macOS', app]);

// Verify both CPU slices, embedded ad-hoc signatures and pack before distributing.
// Preserve executable bits and symlinks when creating the Mac ZIP on Linux.
run('python3', ['-c', String.raw`
import hashlib,json,os,pathlib,plistlib,stat,struct,sys,zipfile
root=pathlib.Path(sys.argv[1]); project=root/'godot-native'; out=root/'dist/native-demo'
app=project/'exports/Wildfall Emberwood.app'
plist=plistlib.loads((app/'Contents/Info.plist').read_bytes())
assert plist['CFBundleIdentifier']=='com.maddoxmoye.wildfall.emberwood'
binary=app/'Contents/MacOS'/plist['CFBundleExecutable']
data=binary.read_bytes()
magic,count=struct.unpack_from('>II',data)
assert magic in (0xcafebabe,0xcafebabf), 'Expected universal Mach-O binary'
assert count==2, 'Expected exactly Apple Silicon and Intel slices'
architectures=[]
for i in range(count):
    at=8+i*(32 if magic==0xcafebabf else 20)
    if magic==0xcafebabf: cpu,subtype,offset,size,align,reserved=struct.unpack_from('>IIQQII',data,at)
    else: cpu,subtype,offset,size,align=struct.unpack_from('>IIIII',data,at)
    architectures.append({0x1000007:'x86_64',0x100000c:'arm64'}[cpu])
    assert struct.unpack_from('<I',data,offset)[0]==0xfeedfacf, 'Expected 64-bit Mach-O slice'
    ncmds=struct.unpack_from('<I',data,offset+16)[0]
    command=offset+32; signature=None
    for _ in range(ncmds):
        kind,length=struct.unpack_from('<II',data,command)
        assert length>=8
        if kind==0x1d:
            start,extent=struct.unpack_from('<II',data,command+8)
            signature=data[offset+start:offset+start+extent]
        command+=length
    assert signature, 'Missing executable code signature'
    sig_magic,sig_length,sig_count=struct.unpack_from('>III',signature)
    assert sig_magic==0xfade0cc0, 'Invalid code-signature container'
    directories=[]
    for j in range(sig_count):
        slot,position=struct.unpack_from('>II',signature,12+j*8)
        if slot==0 or 0x1000<=slot<0x1006:
            directory_magic,directory_length,version,flags=struct.unpack_from('>IIII',signature,position)
            assert directory_magic==0xfade0c02
            assert flags&2, 'Expected explicit ad-hoc signing'
            hash_offset,identifier_offset,special_slots,code_slots,code_limit=struct.unpack_from('>IIIII',signature,position+16)
            hash_size,hash_type,platform,page_power=struct.unpack_from('>BBBB',signature,position+36)
            hasher={1:hashlib.sha1,2:hashlib.sha256,3:hashlib.sha256,4:hashlib.sha384}[hash_type]
            page_size=1<<page_power
            assert code_limit<=size and code_slots==(code_limit+page_size-1)//page_size
            for page in range(code_slots):
                signed_bytes=data[offset+page*page_size:offset+min((page+1)*page_size,code_limit)]
                expected=signature[position+hash_offset+page*hash_size:position+hash_offset+(page+1)*hash_size]
                assert hasher(signed_bytes).digest()[:hash_size]==expected, 'Executable signature page hash mismatch'
            directories.append(slot)
    assert directories, 'Missing signed code directory'
assert set(architectures)=={'arm64','x86_64'}
assert (app/'Contents/_CodeSignature/CodeResources').is_file(), 'Missing bundle resource signature'
packs=list((app/'Contents/Resources').glob('*.pck'))
assert len(packs)==1 and packs[0].read_bytes()[:4]==b'GDPC', 'Missing game pack'

launch='''#!/bin/bash
set -euo pipefail
emberwood_dir="$(cd "$(dirname "$0")" && pwd)"
open -n "$emberwood_dir/Wildfall Emberwood.app" --args --rendering-method gl_compatibility --rendering-driver opengl3
'''
def write_bytes(z,name,value,mode=0o644):
    entry=zipfile.ZipInfo(name)
    entry.create_system=3;entry.external_attr=(stat.S_IFREG|mode)<<16
    entry.compress_type=zipfile.ZIP_DEFLATED
    z.writestr(entry,value)

with zipfile.ZipFile(out/'Wildfall-Emberwood-macOS.zip','w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
    for item in sorted(app.rglob('*')):
        name='Wildfall Emberwood/'+str(item.relative_to(app.parent))
        if item.is_symlink():
            entry=zipfile.ZipInfo(name);entry.create_system=3;entry.external_attr=(stat.S_IFLNK|0o777)<<16
            archive.writestr(entry,os.readlink(item).encode())
        elif item.is_file():
            mode=0o755 if os.access(item,os.X_OK) else 0o644
            write_bytes(archive,name,item.read_bytes(),mode)
    write_bytes(archive,'Wildfall Emberwood/Launch in Compatibility Mode.command',launch.encode(),0o755)
    write_bytes(archive,'Wildfall Emberwood/START HERE.md',(project/'MAC_README.md').read_bytes())
    for item in sorted((project/'licenses').glob('*.txt')):
        write_bytes(archive,'Wildfall Emberwood/Licenses/'+item.name,item.read_bytes())

with zipfile.ZipFile(out/'Wildfall-Emberwood-source.zip','w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
    for item in sorted(project.rglob('*')):
        relative=item.relative_to(project)
        if not item.is_file() or any((part.startswith('.') and part!='.gdignore') or part=='exports' for part in relative.parts) or item.suffix=='.import': continue
        write_bytes(archive,'godot-native/'+str(relative),item.read_bytes())

with zipfile.ZipFile(out/'Wildfall-Emberwood-macOS.zip') as archive:
    executable=archive.getinfo('Wildfall Emberwood/Wildfall Emberwood.app/Contents/MacOS/'+plist['CFBundleExecutable'])
    assert (executable.external_attr>>16)&0o111, 'Executable mode missing from ZIP'
    assert archive.testzip() is None, 'Corrupt ZIP member'

print('MACOS_BUNDLE_VERIFIED: Apple Silicon + Intel, ad-hoc signature page hashes, game pack, executable ZIP permissions and licenses')
print('APP_EXECUTABLE: '+plist['CFBundleExecutable'])
`, root]);

const releaseFiles = ['Wildfall-Emberwood-macOS.zip', 'Wildfall-Emberwood-source.zip'];
const files = {};
for (const name of releaseFiles) {
  const bytes = await readFile(path.join(out, name));
  files[name] = {bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex')};
}
const git = args => spawnSync('git', args, {cwd: root, encoding: 'utf8'}).stdout.trim();
const metadata = {
  engine: 'Godot 4.6.3', target: 'macOS universal (arm64 + x86_64)',
  signing: 'ad-hoc', notarized: false, macRuntimeTested: false,
  sourceRevision: git(['rev-parse', 'HEAD']), sourceDirty: Boolean(git(['status', '--porcelain'])),
  builtAt: new Date().toISOString(), headlessChecks: checks, files,
};
await writeLanding(metadata);
console.log(`Built universal Mac app and source downloads: dist/native-demo/ (${Math.ceil(files[releaseFiles[0]].bytes / 1024 / 1024)} MB app ZIP).`);

async function writeLanding(metadata) {
const files = metadata.files;
const releaseFiles = ['Wildfall-Emberwood-macOS.zip', 'Wildfall-Emberwood-source.zip'];
for (const name of releaseFiles) {
  if (!Number.isSafeInteger(files?.[name]?.bytes) || !/^[a-f0-9]{64}$/.test(files?.[name]?.sha256 || '')) throw new Error(`Invalid release metadata for ${name}`);
}
await writeFile(path.join(out, 'build-info.json'), JSON.stringify(metadata, null, 2) + '\n');
await writeFile(path.join(out, 'SHA256SUMS.txt'), releaseFiles.map(name => `${files[name].sha256}  ${name}`).join('\n') + '\n');
const download = name => (releaseLinks ? releaseBase : '') + name;
await copyFile(path.join(project, 'MAC_README.md'), path.join(out, 'MAC_README.md'));
const heroCandidates = ['preview/emberwood.jpg', 'preview/emberwood.png', 'assets/emberwood-preview.jpg'];
let hero = '';
for (const relative of heroCandidates) {
  if (await exists(path.join(project, relative))) {
    hero = 'emberwood-preview' + path.extname(relative);
    await copyFile(path.join(project, relative), path.join(out, hero));
    break;
  }
}
const hasMotion = await exists(path.join(project, 'preview/emberwood-motion.mp4'));
if (hasMotion) await copyFile(path.join(project, 'preview/emberwood-motion.mp4'), path.join(out, 'emberwood-motion.mp4'));
const size = Math.ceil(files[releaseFiles[0]].bytes / 1024 / 1024);
const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#111c1e"><title>Wildfall · The Emberwood for Mac</title><style>
*{box-sizing:border-box}body{margin:0;background:#101a1c;color:#ede7d8;font-family:system-ui,-apple-system,sans-serif;line-height:1.65}main{width:min(1000px,100% - 44px);margin:56px auto}.eyebrow{font-size:11px;letter-spacing:4px;color:#c7b17a}h1{font:clamp(44px,7vw,78px)/1.04 Georgia,serif;font-weight:400;margin:22px 0}p{max-width:690px;color:#b7c7c1}a{color:#e6cc8d}.download{display:inline-block;padding:16px 24px;background:#e8dfc7;color:#192723;text-decoration:none;border-radius:6px;font-weight:650;margin:18px 0 8px}.meta{font-size:12px;color:#9cb1a7}img,video{width:100%;border:1px solid #63766b45;border-radius:10px;margin:30px 0;display:block}section{border-top:1px solid #d9d9c42b;margin-top:34px;padding-top:24px}h2{font:27px Georgia,serif;font-weight:400}ol{padding-left:24px;max-width:760px;color:#c3d0c8}li{padding:7px 0}.links{display:flex;gap:22px;flex-wrap:wrap;font-size:13px;margin-top:24px}footer{margin:42px 0;color:#8fa399;font-size:12px}a:focus-visible{outline:3px solid #efcf7d;outline-offset:5px}
</style></head><body><main><div class="eyebrow">WILDFALL / NATIVE MAC STUDY</div><h1>The Emberwood.</h1><p>Step into a woodland ruin with Rowan, the Forest Fox and the Briar King. A downloadable combat and graphics study with native controls, lighting and quality settings.</p><a class="download" href="${download('Wildfall-Emberwood-macOS.zip')}" download>Download for Mac ↓</a><div class="meta">Apple Silicon + Intel · ${size} MB · Godot included · Tuned for M1 / 8 GB</div>${hasMotion ? `<video controls playsinline muted loop preload="metadata" poster="${hero}" aria-label="Native combat animation preview"><source src="emberwood-motion.mp4" type="video/mp4"></video><p class="meta">Animation preview rendered frame by frame from the native project. This is a visual preview, not a Mac performance recording.</p>` : hero ? `<img src="${hero}" alt="The Emberwood woodland ruin combat scene">` : ''}<section><h2>Your first visit.</h2><ol><li>Download and unzip, then open <strong>Wildfall Emberwood.app</strong>. You can move it to Applications.</li><li>This test app is ad-hoc signed and has not been notarized by Apple. If macOS blocks it, use <strong>System Settings → Privacy & Security → Open Anyway</strong> for Wildfall Emberwood, then confirm Open.</li><li>Start with <strong>Balanced</strong> graphics. For a lighter rendering fallback, use the included <strong>Launch in Compatibility Mode.command</strong> beside the app.</li></ol><p>The app contains both Mac processor versions. The default Metal renderer targets your M1 Mac with macOS 15.3.2. The app bundle and gameplay are checked during the build; Mac frame rate still needs to be measured on your machine.</p></section><div class="links"><a href="MAC_README.md">Mac setup & controls</a><a href="${download('Wildfall-Emberwood-source.zip')}" download>Editable Godot project</a><a href="SHA256SUMS.txt">Download checksums</a><a href="../arena-demo/">Browser combat demo</a></div><footer>WASD move · Space dash · E salvo · Right-drag camera · P / Escape pause<br>Engine and third-party licenses are included in the download.</footer></main></body></html>`;
await writeFile(path.join(out, 'index.html'), html);
}
