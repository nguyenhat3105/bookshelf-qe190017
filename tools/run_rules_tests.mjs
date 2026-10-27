import { spawn } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';

const env = {...process.env};
if (process.platform === 'win32') {
  // Windows packaged hosts can redirect the default temp directory, preventing
  // Java NIO's internal local socket from connecting. Keep it in the project.
  const socketDirectory = resolve('.sockets');
  mkdirSync(socketDirectory, {recursive:true});
  env.JAVA_TOOL_OPTIONS = `${env.JAVA_TOOL_OPTIONS ?? ''} -Djdk.net.unixdomain.tmpdir="${socketDirectory}"`.trim();
}
const child = spawn(process.execPath, [resolve('node_modules/firebase-tools/lib/bin/firebase.js'),
  'emulators:exec', '--only', 'firestore', '--project', 'demo-bookshelf',
  'node --test test/firestore.rules.test.mjs'], {env, stdio:'inherit'});
child.on('error', error => { console.error(error.message); process.exitCode = 1; });
child.on('exit', code => { process.exitCode = code ?? 1; });
