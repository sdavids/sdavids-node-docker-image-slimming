const path = require('path');
const nodeExternals = require('webpack-node-externals');

// https://webpack.js.org/configuration/#options
module.exports = {
  mode: 'production',
  target: 'node14',
  externals: nodeExternals(),
  entry: path.resolve(__dirname, 'src/js/server.js'),
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
    publicPath: '/',
  },
};
