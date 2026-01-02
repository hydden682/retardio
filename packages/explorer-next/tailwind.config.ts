import type { Config } from "tailwindcss";

const config: Config = {
    content: [
        "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
        "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
        "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
    ],
    theme: {
        extend: {
            colors: {
                background: "#0f172a", // Slate-900 (Dripscan-like deep blue/black)
                foreground: "#f8fafc", // Slate-50
                card: "#1e293b",       // Slate-800
                "card-hover": "#334155", // Slate-700
                border: "#334155",     // Slate-700
                primary: "#00d4ff",    // Retardio Cyan
                secondary: "#10b981",  // Emerald-500
                danger: "#ef4444",
                muted: "#94a3b8",      // Slate-400
            },
            fontFamily: {
                sans: ['var(--font-inter)', 'sans-serif'],
                mono: ['var(--font-roboto-mono)', 'monospace'],
            },
            backgroundImage: {
                "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
            },
        },
    },
    plugins: [],
};
export default config;
