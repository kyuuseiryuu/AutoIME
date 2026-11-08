const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const esbuild = require('esbuild');

const rootDir = path.resolve(__dirname, '..');

// 1. 获取 Git Short Commit Hash
let commitHash = process.env.COMMIT_HASH || '';
if (!commitHash) {
  try {
    commitHash = execSync('git rev-parse --short HEAD', { cwd: rootDir, stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim();
  } catch (e) {
    commitHash = 'dev';
  }
}

// 2. 动态检测版本号 (优先级: process.env.APP_VERSION -> Git Tag -> package.json)
let version = process.env.APP_VERSION || '';
if (!version) {
  try {
    const gitTag = execSync('git describe --tags --abbrev=0', { cwd: rootDir, stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim();
    if (gitTag) version = gitTag;
  } catch {}
}
if (!version) {
  try {
    const pkg = JSON.parse(fs.readFileSync(path.join(rootDir, 'package.json'), 'utf-8'));
    if (pkg.version) {
      version = pkg.version.startsWith('v') ? pkg.version : `v${pkg.version}`;
    }
  } catch {}
}
if (!version) version = 'v1.0.0';

// 3. 动态获取提交/构建时间 (UTC ISO 8601)
let buildTime = '';
try {
  const commitIso = execSync('git log -1 --format=%cI', { cwd: rootDir, stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim();
  if (commitIso) {
    buildTime = new Date(commitIso).toISOString();
  }
} catch {}
if (!buildTime) {
  buildTime = new Date().toISOString();
}

console.log(`🔨 Building AutoIME UI Bundle [Version: ${version}, Commit: #${commitHash}, Time: ${buildTime}]...`);

// 4. 写入/更新 version.json
const versionInfo = {
  version,
  commit: commitHash,
  buildTime
};
fs.writeFileSync(path.join(rootDir, 'version.json'), JSON.stringify(versionInfo, null, 2), 'utf-8');
console.log('📄 Generated version.json');

// 5. 运行 esbuild 编译 React 代码
try {
  esbuild.buildSync({
    entryPoints: [path.join(rootDir, 'ui', 'src', 'index.jsx')],
    bundle: true,
    minify: true,
    outfile: path.join(rootDir, 'ui', 'html', 'app.bundle.js'),
    define: {
      'process.env.COMMIT_HASH': JSON.stringify(commitHash),
      'process.env.APP_VERSION': JSON.stringify(version),
      'process.env.BUILD_TIME': JSON.stringify(buildTime)
    }
  });
  console.log('✅ Built ui/html/app.bundle.js successfully.');
} catch (err) {
  console.error('❌ Build failed:', err);
  process.exit(1);
}
