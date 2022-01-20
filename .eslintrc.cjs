// https://eslint.org/docs/user-guide/configuring

module.exports = {
  env: {
    node: true,
    es2021: true,
  },
  parserOptions: {
    sourceType: 'module',
  },
  extends: ['eslint:all', 'plugin:json/recommended', 'prettier'],
  rules: {
    'capitalized-comments': 'off',
    'id-length': 'off',
    'no-console': 'off',
    'no-magic-numbers': 'off',
    'no-ternary': 'off',
    'one-var': 'off',
    'sort-keys': 'off',
    radix: 'off',
  },
  ignorePatterns: ['dist/*'],
  overrides: [
    {
      files: ['*.js', '*.cjs', '*.mjs'],
    },
  ],
};
