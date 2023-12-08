// https://github.com/okonet/lint-staged#configuration

module.exports = {
  '*.{js,cjs,mjs,json}': ['eslint', 'prettier --check'],
  '*.yaml': ['prettier --check'],
};
