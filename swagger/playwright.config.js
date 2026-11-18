import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './browser-tests',
  use: { baseURL: 'http://localhost:8080', viewport: { width: 1440, height: 1100 } },
  webServer: { command: 'npm run swagger:local', url: 'http://localhost:8080', reuseExistingServer: false },
  reporter: [['list'], ['html', { open: 'never' }]]
});
