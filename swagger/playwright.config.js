import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './browser-tests',
  use: { baseURL: 'http://127.0.0.1:8080' },
  webServer: { command: 'npm run serve', url: 'http://127.0.0.1:8080', reuseExistingServer: false },
  reporter: [['list'], ['html', { open: 'never' }]]
});
