// Copy this file to eslint.config.mjs beside the project's tsconfig.json.
// Use Node.js 20.11 or later. Install these development dependencies:
// npm install -D eslint@9 @eslint/js@9 typescript@~6.0.3 typescript-eslint globals
// npm install -D eslint-plugin-react eslint-plugin-react-hooks
// npm install -D eslint-plugin-import-x eslint-import-resolver-typescript
// npm install -D @tanstack/eslint-plugin-start @tanstack/eslint-plugin-router @tanstack/eslint-plugin-query
// Include application TypeScript files in tsconfig.json. Deno owns formatting.
import js from "@eslint/js";
import query from "@tanstack/eslint-plugin-query";
import router from "@tanstack/eslint-plugin-router";
import start from "@tanstack/eslint-plugin-start";
import { defineConfig, globalIgnores } from "eslint/config";
import { createTypeScriptImportResolver } from "eslint-import-resolver-typescript";
import importX from "eslint-plugin-import-x";
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";
import globals from "globals";
import tseslint from "typescript-eslint";

let startRecommended = start.configs["flat/recommended"];
if (process.platform === "win32") {
  // Start 0.1.0 misses standalone async client components on Windows.
  // Match ESLint filenames to TypeScript's forward-slash graph keys.
  const asyncClientRule = start.rules["no-async-client-component"];
  const portableStart = {
    ...start,
    rules: {
      ...start.rules,
      "no-async-client-component": {
        ...asyncClientRule,
        create(context) {
          return asyncClientRule.create(Object.create(context, {
            filename: { value: context.filename.replaceAll("\\", "/") },
          }));
        },
      },
    },
  };
  startRecommended = startRecommended.map((config) => ({
    ...config,
    plugins: { ...config.plugins, "@tanstack/start": portableStart },
  }));
}

export default defineConfig(
  globalIgnores([
    "dist/**",
    "build/**",
    "coverage/**",
    ".output/**",
    ".tanstack/**",
    "**/routeTree.gen.ts",
  ]),
  {
    files: ["**/*.{js,jsx,mjs,cjs,ts,tsx,mts,cts}"],
    extends: [js.configs.recommended, importX.flatConfigs.recommended],
    languageOptions: { globals: { ...globals.browser, ...globals.node } },
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
      router.configs["flat/recommended"],
      query.configs["flat/recommended"],
    ],
    settings: { react: { version: "detect" } },
  },
  {
    files: ["**/*.{ts,tsx,mts,cts}"],
    extends: [
      tseslint.configs.recommendedTypeChecked,
      importX.flatConfigs.typescript,
      startRecommended,
    ],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      // TanStack Router uses these objects for navigation control flow.
      "@typescript-eslint/only-throw-error": ["error", {
        allow: [
          {
            from: "package",
            package: "@tanstack/router-core",
            name: "Redirect",
          },
          {
            from: "package",
            package: "@tanstack/router-core",
            name: "NotFoundError",
          },
        ],
      }],
    },
  },
  {
    files: ["**/*.{ts,tsx}"],
    rules: { "react/prop-types": "off" },
  },
  {
    // Configuration files can sit outside the application's TypeScript project.
    files: ["**/*.config.{js,mjs,cjs,ts,mts,cts}", "**/eslint.config.*"],
    extends: [tseslint.configs.disableTypeChecked],
    languageOptions: { globals: globals.node },
    rules: {
      // These third-party rules also require the application's type information.
      "@tanstack/start/no-client-code-in-server-component": "off",
      "@tanstack/start/no-async-client-component": "off",
    },
  },
);
