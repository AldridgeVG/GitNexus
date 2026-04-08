#!/usr/bin/env node
/**
 * Build script that compiles gitnexus and inlines gitnexus-shared into the dist.
 *
 * Steps:
 *  1. Build gitnexus-shared (tsc)
 *  2. Build gitnexus (tsc)
 *  3. Copy gitnexus-shared/dist → dist/_shared
 *  4. Rewrite bare 'gitnexus-shared' specifiers → relative paths
 */
import { execSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const SHARED_ROOT = path.resolve(ROOT, '..', 'gitnexus-shared');
const DIST = path.join(ROOT, 'dist');
const SHARED_DEST = path.join(DIST, '_shared');

// 检测是否在全局安装模式下（prepare 钩子运行，但依赖未安装）
function findTsc(cwd) {
  // 优先使用本地 node_modules 的 tsc
  const localTsc = path.join(cwd, 'node_modules', '.bin', 'tsc');
  if (fs.existsSync(localTsc)) return localTsc;

  // Windows 下的 .cmd 变体
  const localTscCmd = path.join(cwd, 'node_modules', '.bin', 'tsc.cmd');
  if (fs.existsSync(localTscCmd)) return localTscCmd;

  // 回退到 npx（全局安装时可能没有本地 typescript）
  return 'npx tsc';
}

// 如果 dist 已存在且不是开发模式，跳过构建（全局安装时使用预构建产物）
const isGlobalInstall =
  process.env.npm_config_global === 'true' || process.env.npm_config_global === '';
const hasDist = fs.existsSync(DIST) && fs.existsSync(path.join(DIST, 'cli', 'index.js'));

if (isGlobalInstall && hasDist) {
  console.log('[build] global install with existing dist, skipping build');
  process.exit(0);
}

// ── 1. Build gitnexus-shared ───────────────────────────────────────
console.log('[build] compiling gitnexus-shared…');
const sharedTsc = findTsc(SHARED_ROOT);
execSync(sharedTsc, { cwd: SHARED_ROOT, stdio: 'inherit' });

// ── 2. Build gitnexus ──────────────────────────────────────────────
console.log('[build] compiling gitnexus…');
const rootTsc = findTsc(ROOT);
execSync(rootTsc, { cwd: ROOT, stdio: 'inherit' });

// ── 3. Copy shared dist ────────────────────────────────────────────
console.log('[build] copying shared module into dist/_shared…');
fs.cpSync(path.join(SHARED_ROOT, 'dist'), SHARED_DEST, { recursive: true });

// ── 4. Rewrite imports ─────────────────────────────────────────────
console.log('[build] rewriting gitnexus-shared imports…');
let rewritten = 0;

function rewriteFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  if (!content.includes('gitnexus-shared')) return;

  const relDir = path.relative(path.dirname(filePath), SHARED_DEST);
  // Always use posix separators and point to the package index
  const relImport = relDir.split(path.sep).join('/') + '/index.js';

  const updated = content
    .replace(/from\s+['"]gitnexus-shared['"]/g, `from '${relImport}'`)
    .replace(/import\(\s*['"]gitnexus-shared['"]\s*\)/g, `import('${relImport}')`);

  if (updated !== content) {
    fs.writeFileSync(filePath, updated);
    rewritten++;
  }
}

function walk(dir, extensions, cb) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full, extensions, cb);
    } else if (extensions.some((ext) => entry.name.endsWith(ext))) {
      cb(full);
    }
  }
}

walk(DIST, ['.js', '.d.ts'], rewriteFile);

// ── 5. Make CLI entry executable ────────────────────────────────────
const cliEntry = path.join(DIST, 'cli', 'index.js');
if (fs.existsSync(cliEntry)) fs.chmodSync(cliEntry, 0o755);

console.log(`[build] done — rewrote ${rewritten} files.`);
