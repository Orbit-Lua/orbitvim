import { FlatCompat } from "@eslint/eslintrc";

const compat = new FlatCompat({
  // import.meta.dirname is available after Node.js v20.11.0
  baseDirectory: import.meta.dirname,
});

// https://nextjs.org/docs/app/api-reference/config/eslint
// https://nextjs.org/docs/app/api-reference/config/eslint#setup-eslint
const eslintConfig = [
  ...compat.config({
    ignorePatterns: [".next"],
    extends: [
      // next.js with typescript
      "next/core-web-vitals",
      "next/typescript",

      // eslint-plugin-import
      "plugin:import/recommended",
      "plugin:import/typescript",
    ],
    settings: {
      next: {
        rootDir: "./src/",
      },
      "import/resolver": {
        // https://github.com/import-js/eslint-import-resolver-typescript#configuration
        "typescript": true,
        "node": true,
      },
    },
    rules: {
      // Fix Unused Variables
      // Set TypeScript-related unused variable rules to warn
      "@typescript-eslint/no-unused-vars": ["warn", {
        // Optional configuration, e.g., allowing unused arguments to start with an underscore
        argsIgnorePattern: "^_",
        varsIgnorePattern: "^_",
        caughtErrorsIgnorePattern: "^_",
      }],

      // Set JavaScript built-in unused variable rule to warn (usually overridden by TS rule, but kept as a safeguard)
      // "no-unused-vars": ["warn", {
      //    argsIgnorePattern: "^_",
      //    varsIgnorePattern: "^_",
      //    caughtErrorsIgnorePattern: "^_",
      // }],

      // Fix Undefined Variables
      // Although not unused, this is often downgraded from error to avoid conflicts with certain external libraries
      // "no-undef": "warn",

      // eslint-plugin-import
      "import/order": ["warn", {
        "groups": [
          // Imports of builtins are first
          "builtin",
          // Then sibling and parent imports. They can be mingled together
          ["sibling", "parent"],
          // Then index file imports
          "index",
          // Then any arcane TypeScript imports
          "object",
          // Then the omitted imports: internal, external, type, unknown
        ],
      }],
    },
  }),
];

export default eslintConfig;
