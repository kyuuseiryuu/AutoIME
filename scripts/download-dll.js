const path = require('path');
const { spawnSync } = require('child_process');

const ps1 = path.join(__dirname, 'download-dll.ps1');
const result = spawnSync('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ps1], {
  stdio: 'inherit'
});

process.exit(result.status || 0);
