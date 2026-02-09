module.exports = {
  presets: ['module:@react-native/babel-preset'],
  plugins: [
    [
      'module-resolver',
      {
        root: ['./src'],
        extensions: ['.ios.js', '.android.js', '.js', '.ts', '.tsx', '.json'],
        alias: {
          '@shared': './src/shared',
          '@screens': './src/screens',
          '@components': './src/components',
          '@navigation': './src/navigation',
        },
      },
    ],
  ],
};
