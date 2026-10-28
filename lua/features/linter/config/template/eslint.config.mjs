import js from "@eslint/js";
import next from "@next/eslint-plugin-next";
import importPlugin from "eslint-plugin-import";
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";
import { defineConfig } from "eslint/config";
import globals from "globals";
import tseslint from "typescript-eslint";

// The root directory of the Next.js project in the original configuration
const NEXTJS_ROOT_DIR = "./src/";

const eslintConfig = defineConfig([
  // Base JavaScript Recommended Rules
  // Provides the basic ESLint core rules
  js.configs.recommended,

  // Ignore Patterns
  // Retains the original setting's requirement to ignore the .next folder
  {
    ignores: [".next"],
  },

  // TypeScript Recommended Rules
  // Enables TypeScript-specific rules and handles conflicts with base JS rules
  ...tseslint.configs.recommended,

  // Environments & Globals
  {
    languageOptions: {
      // Enable ES modules syntax parsing
      sourceType: "module",
      // Configure global variables for Node.js and Browser environments
      globals: {
        ...globals.browser,
        ...globals.node,
        React: true,
      },
    },
  },

  // React / React Hooks Rules
  {
    files: ["**/*.{js,jsx,ts,tsx}"],
    plugins: {
      react,
      "react-hooks": reactHooks,
    },
    settings: {
      // Detect React version
      react: {
        version: "detect",
      },
    },
    rules: {
      // Enable React recommended rules and React Hooks rules
      ...react.configs.recommended.rules,
      ...reactHooks.configs.recommended.rules,

      "no-undef": "error",

      // Disable the base 'no-unused-vars' rule, using the TypeScript-specific version instead
      "no-unused-vars": "off",
      "react/react-in-jsx-scope": "off",

      // Unused Variables Fix - Retain Original Setting
      // Set '@typescript-eslint/no-unused-vars' to 'warn'
      "@typescript-eslint/no-unused-vars": ["warn", {
        argsIgnorePattern: "^_",
        varsIgnorePattern: "^_",
        caughtErrorsIgnorePattern: "^_",
      }],
      // Ensure React is marked as used in JSX/TSX files (for older React versions, not needed for new ones)
      // 'react/react-in-jsx-scope': 'off',
    },
  },

  // Next.js Specific Rules
  {
    files: ["**/*.{js,jsx,ts,tsx}"],
    plugins: {
      "@next/next": next,
    },
    settings: {
      // Ensure the Next.js plugin knows the project root directory (Retain original setting)
      "@next/next": {
        rootDir: NEXTJS_ROOT_DIR,
      },
    },
    rules: {
      // Enable Next.js recommended rules and Core Web Vitals rules
      ...next.configs.recommended.rules,
      ...next.configs["core-web-vitals"].rules,
      // The original setting's 'next/typescript' is already covered by tseslint.configs.recommended and next rules here
    },
  },

  // Eslint-Plugin-Import Rules
  {
    files: ["**/*.{js,jsx,ts,tsx}"],
    plugins: {
      import: importPlugin,
    },
    settings: {
      // Configure 'import/resolver' to resolve TypeScript paths (Retain original setting)
      "import/resolver": {
        typescript: true,
        node: true,
      },
    },
    rules: {
      // Enable some 'import/recommended' rules
      "import/no-unresolved": "error",
      "import/named": "error",
      "import/no-duplicates": "error",

      // Import Order Fix - Retain Original Setting
      "import/order": ["warn", {
        "groups": [
          "builtin", // Node.js built-in modules
          ["sibling", "parent"], // Sibling and parent paths
          "index", // index files in the current directory
          "object", // 'object' from the original configuration (often arcane/unknown)
          "external", // External modules (automatically included if not specified in groups)
          "type", // Type imports
          "unknown", // Other uncategorized imports
        ],
        // Add newlines to separate groups
        "newlines-between": "always",
        // Sort by alphabetical order
        "alphabetize": { "order": "asc", "caseInsensitive": true },
      }],
    },
  },
]);

export default eslintConfig;
