import nodeExternals from 'webpack-node-externals';
import { resolve } from 'path';

// https://webpack.js.org/configuration/#options
export default {
  mode: 'production',
  target: 'node20',
  externals: nodeExternals(),
  entry: resolve(import.meta.dirname, 'src/js/server.mjs'),
  output: {
    filename: 'server.js',
    path: resolve(import.meta.dirname, 'dist'),
    publicPath: '/',
  },
};
