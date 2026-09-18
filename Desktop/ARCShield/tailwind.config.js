/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"DM Sans"', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
        display: ['Sora', '"DM Sans"', 'sans-serif'],
        heading: ['Sora', '"DM Sans"', 'sans-serif'],
        mono: ['"DM Mono"', 'ui-monospace', 'SFMono-Regular', 'Menlo', 'monospace'],
      },
      colors: {
        brand: {
          50:  '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
      },
      boxShadow: {
        'card':       '0 1px 3px rgba(0,0,0,0.04), 0 4px 16px rgba(0,0,0,0.04)',
        'card-hover': '0 2px 8px rgba(0,0,0,0.06), 0 8px 32px rgba(0,0,0,0.07)',
        'selected':   '0 0 0 2px #2563eb',
        'xs':         '0 1px 2px rgba(0,0,0,0.05)',
        'glow-blue':  '0 0 20px rgba(37,99,235,0.15)',
        'glow-rose':  '0 0 20px rgba(244,63,94,0.12)',
      },
      borderRadius: {
        '2xl': '1rem',
        '3xl': '1.5rem',
        '4xl': '2rem',
      },
      animation: {
        'fade-in':      'fadeIn 0.25s ease',
        'slide-up':     'slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1)',
        'pulse-dot':    'pulseDot 1.8s ease-in-out infinite',
        'shimmer':      'shimmer 2s linear infinite',
      },
      keyframes: {
        fadeIn:   { from: { opacity: 0 }, to: { opacity: 1 } },
        slideUp:  { from: { opacity: 0, transform: 'translateY(8px)' }, to: { opacity: 1, transform: 'translateY(0)' } },
        pulseDot: {
          '0%, 100%': { transform: 'scale(1)', opacity: 1 },
          '50%':      { transform: 'scale(1.6)', opacity: 0.5 },
        },
        shimmer: {
          from: { backgroundPosition: '200% 0' },
          to:   { backgroundPosition: '-200% 0' },
        },
      },
    },
  },
  plugins: [],
};
