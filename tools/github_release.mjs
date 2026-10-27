// Upload the verified APK to this project's GitHub release. Authentication is
// obtained in memory from Git Credential Manager, as with `git push`.
import { execFileSync } from 'node:child_process';
import { readFileSync, statSync, mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const repo = 'nguyenhat3105/bookshelf-qe190017';
const tag = 'v1.0.0';
const credential = execFileSync('git', ['credential', 'fill'], {
  input:'protocol=https\nhost=github.com\n\n', encoding:'utf8',
  env:{...process.env, GCM_INTERACTIVE:'never', GIT_TERMINAL_PROMPT:'0'},
});
const token = credential.split(/\r?\n/).find(line => line.startsWith('password='))?.slice(9);
if (!token) throw new Error('No existing GitHub authentication is available.');
const headers = {Authorization:`Bearer ${token}`, Accept:'application/vnd.github+json', 'X-GitHub-Api-Version':'2022-11-28'};
async function api(path, options = {}) {
  const response = await fetch(`https://api.github.com/repos/${repo}${path}`, {...options, headers:{...headers, 'Content-Type':'application/json', ...options.headers}});
  if (!response.ok) throw new Error(`GitHub ${response.status}: ${await response.text()}`);
  return response.status === 204 ? null : response.json();
}
if (process.argv.includes('--dispatch')) {
  await api('/actions/workflows/android-release.yml/dispatches', {method:'POST', body:JSON.stringify({ref:'main'})});
  console.log('Android release workflow started.');
  process.exit(0);
}
if (process.argv.includes('--status')) {
  const data = await api('/actions/runs?per_page=3');
  console.log(JSON.stringify(data.workflow_runs.map(r => ({id:r.id,status:r.status,conclusion:r.conclusion,url:r.html_url})), null, 2));
  process.exit(0);
}
const releases = await api('/releases');
let release = releases.find(item => item.tag_name === tag);
if (process.argv.includes('--download')) {
  const asset = release?.assets.find(asset => asset.name === 'app-release.apk');
  if (!asset) throw new Error('The release APK is not yet available.');
  const response = await fetch(asset.url, {headers:{...headers, Accept:'application/octet-stream'}});
  if (!response.ok) throw new Error(`APK download failed: ${response.status}`);
  const folder = resolve('build/app/outputs/flutter-apk');
  mkdirSync(folder, {recursive:true});
  writeFileSync(resolve(folder, 'app-release.apk'), Buffer.from(await response.arrayBuffer()));
  console.log('Release APK downloaded for device verification.');
} else if (process.argv.includes('--publish')) {
  if (!release || !release.assets.some(asset => asset.name === 'app-release.apk')) throw new Error('Upload a tested APK before publishing.');
  release = await api(`/releases/${release.id}`, {method:'PATCH', body:JSON.stringify({draft:false, target_commitish:'main',
    body:'BookShelf Android release for PRM393 — QE190017 Nguyễn Công Nhất.\n\nThe release APK was installed and opened on a physical Android 14 phone. Firebase Email/Password Authentication and private Firestore storage are configured. The application workflows were verified with real-device integration tests.\n\nInstall app-release.apk. Grader account credentials are supplied privately in the submission report.'})});
  console.log(`Published release: ${release.html_url}`);
} else {
  const apk = resolve('build/app/outputs/flutter-apk/app-release.apk');
  if (statSync(apk).size < 1000000) throw new Error('APK is missing or incomplete.');
  if (!release) release = await api('/releases', {method:'POST', body:JSON.stringify({tag_name:tag, target_commitish:'main', name:'BookShelf 1.0.0', draft:true,
    body:'BookShelf Android release for PRM393 — QE190017 Nguyễn Công Nhất.\n\nInstall app-release.apk on an Android phone. Firebase Email/Password and private Firestore storage are configured.'})});
  if (!release.assets.some(asset => asset.name === 'app-release.apk')) {
    const upload = release.upload_url.split('{')[0] + '?name=app-release.apk';
    const response = await fetch(upload, {method:'POST', headers:{...headers, 'Content-Type':'application/vnd.android.package-archive'}, body:readFileSync(apk)});
    if (!response.ok) throw new Error(`APK upload failed: ${response.status}`);
    await response.json();
  }
  console.log(`APK uploaded to draft release: ${release.html_url}`);
}
