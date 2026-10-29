// Copy this file beside the project's tsconfig.json. Use Node.js 20.11 or later.
// Install ESLint 9 and these development dependencies:
// npm install -D eslint@9 @eslint/js@9 typescript@~6.0.3 typescript-eslint globals
// npm install -D eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-react-refresh
// npm install -D eslint-plugin-import-x eslint-import-resolver-typescript
// Include application TypeScript files in tsconfig.json. Deno owns formatting.
import js from "@eslint/js";
import { defineConfig, globalIgnores } from "eslint/config";
import { createTypeScriptImportResolver } from "eslint-import-resolver-typescript";
import importX from "eslint-plugin-import-x";
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";
import reactRefresh from "eslint-plugin-react-refresh";
import globals from "globals";
import tseslint from "typescript-eslint";

export default defineConfig(
  globalIgnores(["dist/**", "build/**", "coverage/**"]),
  {
    files: ["**/*.{js,jsx,mjs,cjs,ts,tsx,mts,cts}"],
    extends: [js.configs.recommended, importX.flatConfigs.recommended],
    languageOptions: { globals: globals.browser },
    settings: {
      "import-x/resolver-next": [createTypeScriptImportResolver()],
    },
  },
  {
    files: ["**/*.{js,jsx,ts,tsx}"],
    extends: [
      react.configs.flat.recommended,
      react.configs.flat["jsx-runtime"],
      reactHooks.configs.flat.recommended,
    ],
    settings: { react: { version: "detect" } },
  },
  {
    files: ["**/*.{ts,tsx,mts,cts}"],
    extends: [
      tseslint.configs.recommendedTypeChecked,
      importX.flatConfigs.typescript,
    ],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    files: ["**/*.{ts,tsx}"],
    rules: { "react/prop-types": "off" },
  },
  {
    files: ["**/*.{jsx,tsx}"],
    extends: [reactRefresh.configs.vite],
  },
  {
    // Configuration files can sit outside the application's TypeScript project.
    files: ["**/*.config.{js,mjs,cjs,ts,mts,cts}", "**/eslint.config.*"],
    extends: [tseslint.configs.disableTypeChecked],
    languageOptions: { globals: globals.node },
  },
);
