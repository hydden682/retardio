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
                background: "#000000", // Pure Black
                foreground: "#ffffff", // Pure White
                card: "#111111",       // Dark Gray
                "card-hover": "#1a1a1a", // Slightly Lighter Gray
                border: "#333333",     // Dark Gray Border
                primary: "#FFD700",    // Retardio Gold/Yellow
                secondary: "#E5C100",  // Darker Yellow
                danger: "#ff4444",
                muted: "#888888",      // Neutral Gray
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
