import eslint from '@eslint/js';
import tsParser from '@typescript-eslint/parser';
import reactRefresh from 'eslint-plugin-react-refresh';

const browserGlobals = {
  window: 'readonly',
  document: 'readonly',
  navigator: 'readonly',
  console: 'readonly',
  fetch: 'readonly',
  setInterval: 'readonly',
  clearInterval: 'readonly',
  setTimeout: 'readonly',
  clearTimeout: 'readonly',
  URL: 'readonly',
};

export default [
  {
    ignores: ['dist/**', 'node_modules/**', 'build/**'],
  },
  eslint.configs.recommended,
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
        ecmaFeatures: { jsx: true },
      },
      globals: browserGlobals,
    },
    plugins: {
      'react-refresh': reactRefresh,
    },
    rules: {
      'react-refresh/only-export-components': 'warn',
      '@typescript-eslint/no-unused-vars': 'off',
      'no-unused-vars': 'off',
      'no-undef': 'off',
    },
  },
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: { console: 'readonly' },
    },
  },
];