// https://github.com/okonet/lint-staged#configuration

'use strict';

module.exports = {
  '*.{js,cjs,mjs,json}': ['eslint', 'prettier --check'],
  '*.yaml': ['prettier --check', 'yamllint --strict'],
  '*.sh': ['shellcheck'],
};
