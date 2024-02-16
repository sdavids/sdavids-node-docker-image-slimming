// https://eslint.org/docs/user-guide/configuring

module.exports = {
  root: true,
  env: {
    node: true,
    es2022: true,
  },
  parserOptions: {
    sourceType: 'module',
  },
  extends: ['eslint:all', 'plugin:json/recommended', 'prettier'],
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
  ignorePatterns: ['dist/*'],
  reportUnusedDisableDirectives: true,
  overrides: [
    {
      files: ['*.js', '*.cjs', '*.mjs'],
    },
  ],
};
