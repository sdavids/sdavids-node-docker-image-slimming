// https://github.com/okonet/lint-staged#configuration

module.exports = {
  '*.{js,cjs,mjs,json}': ['eslint', 'prettier --write'],
  '*.yaml': ['prettier --write'],
};
