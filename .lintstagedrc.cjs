// https://github.com/okonet/lint-staged#configuration

module.exports = {
  '*.{js,cjs,mjs,json,yaml}': ['prettier --write'],
};
