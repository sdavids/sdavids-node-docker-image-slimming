// https://eslint.org/docs/latest/use/configure/configuration-files

import globals from 'globals';
import js from '@eslint/js';

// noinspection JSUnusedGlobalSymbols
export default [
  {
    ignores: ['dist/*'],
  },
  js.configs.all,
  {
    name: 'sdavids-node-docker-image-slimming',
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: 'module',
      },
    },
    linterOptions: {
      reportUnusedDisableDirectives: true,
    },
    rules: {
      'capitalized-comments': 'off',
      'id-length': 'off',
      'line-comment-position': 'off',
      'no-console': 'off',
      'no-inline-comments': 'off',
      'no-magic-numbers': 'off',
      'no-ternary': 'off',
      'one-var': 'off',
      'sort-keys': 'off',
      radix: 'off',
    },
  },
];
