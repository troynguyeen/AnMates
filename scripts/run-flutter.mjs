#!/usr/bin/env node
// scripts/run-flutter.mjs — locate the Flutter binary cross-platform and exec it.
//
// Resolution order:
//   1. FLUTTER_BIN env var (full path to flutter / flutter.bat)
//   2. `flutter` on PATH
//   3. Common install locations per platform
//
// Usage from any npm script:
//   node scripts/run-flutter.mjs test integration_test/
//
// Override in any shell:
//   FLUTTER_BIN=/c/flutter/bin/flutter.bat npm run test:e2e

import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { homedir, platform } from 'node:os';
import { join } from 'node:path';

function which(cmd) {
  const isWin = platform() === 'win32';
  const checker = spawnSync(isWin ? 'where' : 'which', [cmd], {
    encoding: 'utf8',
    shell: false,
  });
  if (checker.status !== 0) return null;
  const first = (checker.stdout || '').split(/\r?\n/).find(Boolean);
  return first ? first.trim() : null;
}

function candidates() {
  const home = homedir();
  const isWin = platform() === 'win32';
  const exe = isWin ? 'flutter.bat' : 'flutter';

  if (isWin) {
    return [
      process.env.LOCALAPPDATA && join(process.env.LOCALAPPDATA, 'Pub', 'Cache', 'bin', exe),
      process.env.LOCALAPPDATA && join(process.env.LOCALAPPDATA, 'flutter', 'bin', exe),
      join(home, 'flutter', 'bin', exe),
      join(home, 'fvm', 'default', 'bin', exe),
      join(home, 'AppData', 'Local', 'flutter', 'bin', exe),
      join(home, 'scoop', 'apps', 'flutter', 'current', 'bin', exe),
      'C:\\flutter\\bin\\flutter.bat',
      'C:\\src\\flutter\\bin\\flutter.bat',
      'C:\\dev\\flutter\\bin\\flutter.bat',
      'C:\\tools\\flutter\\bin\\flutter.bat',
      'C:\\Program Files\\flutter\\bin\\flutter.bat',
    ].filter(Boolean);
  }
  return [
    join(home, 'flutter', 'bin', exe),
    join(home, 'fvm', 'default', 'bin', exe),
    join(home, 'development', 'flutter', 'bin', exe),
    '/opt/homebrew/bin/flutter',
    '/usr/local/bin/flutter',
    '/usr/bin/flutter',
    '/snap/bin/flutter',
  ];
}

function resolveFlutter() {
  if (process.env.FLUTTER_BIN) {
    if (existsSync(process.env.FLUTTER_BIN)) return process.env.FLUTTER_BIN;
    console.error(`FLUTTER_BIN points at "${process.env.FLUTTER_BIN}" but the file doesn't exist.`);
    process.exit(127);
  }
  const fromPath = which('flutter');
  if (fromPath) return fromPath;
  for (const p of candidates()) {
    if (existsSync(p)) return p;
  }
  return null;
}

const flutter = resolveFlutter();
if (!flutter) {
  console.error([
    "Couldn't find Flutter on this machine.",
    '',
    'Fix one of these:',
    '  1. Add flutter to PATH         (recommended)',
    '  2. Set FLUTTER_BIN env var     e.g. FLUTTER_BIN=C:\\flutter\\bin\\flutter.bat',
    '',
    'Install Flutter: https://docs.flutter.dev/get-started/install',
  ].join('\n'));
  process.exit(127);
}

// Pull an optional --cwd <dir> out of argv before handing off to flutter.
// (Working dir, not a flutter flag — we don't want to pass it through.)
const rawArgs = process.argv.slice(2);
let cwd = process.cwd();
const args = [];
for (let i = 0; i < rawArgs.length; i++) {
  if (rawArgs[i] === '--cwd' && rawArgs[i + 1]) {
    cwd = rawArgs[++i];
  } else if (rawArgs[i].startsWith('--cwd=')) {
    cwd = rawArgs[i].slice('--cwd='.length);
  } else {
    args.push(rawArgs[i]);
  }
}

const child = spawnSync(flutter, args, {
  stdio: 'inherit',
  cwd,
  // `shell: true` lets Windows find .bat files when given just a name.
  shell: platform() === 'win32',
});
process.exit(child.status ?? 1);
