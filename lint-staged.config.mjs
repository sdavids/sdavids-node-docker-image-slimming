// https://github.com/okonet/lint-staged#configuration

// noinspection JSUnusedGlobalSymbols
export default {
  '*.{js,cjs,mjs,json}': ['eslint', 'prettier --check'],
  '*.yaml': ['prettier --check', 'yamllint --strict'],
  '*.sh': ['shellcheck'],
  Dockerfile: ['hadolint --no-color'],
};
