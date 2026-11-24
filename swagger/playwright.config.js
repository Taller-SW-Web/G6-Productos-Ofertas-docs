import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './browser-tests',
  use: { baseURL: `http://localhost:8080${process.env.SWAGGER_BASE_PATH ? `/${process.env.SWAGGER_BASE_PATH.replace(/^\/+|\/+$/g, '')}` : ''}/`, viewport: { width: 1440, height: 1100 } },
  webServer: { command: 'npm run swagger:local', url: `http://localhost:8080${process.env.SWAGGER_BASE_PATH ? `/${process.env.SWAGGER_BASE_PATH.replace(/^\/+|\/+$/g, '')}` : ''}/`, reuseExistingServer: false },
  reporter: [['list'], ['html', { open: 'never' }]]
});
