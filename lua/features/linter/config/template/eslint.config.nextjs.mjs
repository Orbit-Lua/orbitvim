// Copy this file to eslint.config.mjs beside the project's tsconfig.json.
// Use Node.js 20.11 or later.
// Install ESLint 9 and these development dependencies:
// npm install -D eslint@9 @eslint/js@9 eslint-config-next typescript-eslint typescript@~6.0.3
// Match eslint-config-next to the project's Next.js version.
// Include application TypeScript files in tsconfig.json. Deno owns formatting.
import js from "@eslint/js";
import nextVitals from "eslint-config-next/core-web-vitals";
import { defineConfig, globalIgnores } from "eslint/config";
import tseslint from "typescript-eslint";

export default defineConfig(
  js.configs.recommended,
  nextVitals,
  {
    files: ["**/*.{ts,tsx,mts,cts}"],
    extends: [tseslint.configs.recommendedTypeChecked],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    // Configuration files can sit outside the application's TypeScript project.
    files: ["**/*.config.{js,mjs,cjs,ts,mts,cts}", "**/eslint.config.*"],
    extends: [tseslint.configs.disableTypeChecked],
  },
  globalIgnores([
    ".next/**",
    "out/**",
    "build/**",
    "coverage/**",
    "next-env.d.ts",
  ]),
);
