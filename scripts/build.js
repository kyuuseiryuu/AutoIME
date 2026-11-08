const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const esbuild = require('esbuild');

const rootDir = path.resolve(__dirname, '..');

// 1. 获取 Git Short Commit Hash
let commitHash = process.env.COMMIT_HASH || '';
if (!commitHash) {
  try {
    commitHash = execSync('git rev-parse --short HEAD', { cwd: rootDir }).toString().trim();
  } catch (e) {
    commitHash = 'dev';
  }
}
const version = 'v2.0';

console.log(`🔨 Building AutoIME UI Bundle [Version: ${version}, Commit: #${commitHash}]...`);

// 2. 写入/更新 version.json
const versionInfo = {
  version,
  commit: commitHash,
  buildTime: new Date().toISOString()
};
fs.writeFileSync(path.join(rootDir, 'version.json'), JSON.stringify(versionInfo, null, 2), 'utf-8');
console.log('📄 Generated version.json');

// 3. 运行 esbuild 编译 React 代码
try {
  esbuild.buildSync({
    entryPoints: [path.join(rootDir, 'ui', 'src', 'index.jsx')],
    bundle: true,
    minify: true,
    outfile: path.join(rootDir, 'ui', 'html', 'app.bundle.js'),
    define: {
      'process.env.COMMIT_HASH': JSON.stringify(commitHash),
      'process.env.APP_VERSION': JSON.stringify(version)
    }
  });
  console.log('✅ Built ui/html/app.bundle.js successfully.');
} catch (err) {
  console.error('❌ Build failed:', err);
  process.exit(1);
}

