import type { SiteConfig, ThemeConfig, SettingsConfig, UmamiAnalyticsConfig, AnalyticsConfig } from "../types";

// Basic site identity. Replace the domain once it is set up in astro.config.mjs.
export const SITE: SiteConfig = {
    website: "https://sethbwatts.com",
    author: "Seth Watts",
    desc: "Personal academic website of Seth Watts, School of Criminal Justice and Criminology, Texas State University.",
    title: "Seth Watts",
    ogImage: "images/headshot.jpeg",
    postPerPage: 5,
    favicon: "/favicon.svg",
    lang: "en",
};

// Color palettes. Names must match keys in themes.ts (light_ and dark_ prefixes are optional).
export const THEME_CONFIG: ThemeConfig = {
    lightAndDark: true,
    themeLight: "light_default",
    themeDark: "dark_default",
};

export const SETTINGS: SettingsConfig = {
    showTagsInNavbar: false,
    showRSSInFooter: false,
    addDevToolsInProduction: false,
};

// Analytics are off by default. Add an ID to turn one on.
const umami: UmamiAnalyticsConfig = {
    websiteId: "", // e.g., 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    src: "https://cloud.umami.is/script.js", // Default Umami cloud script URL
}

export const ANALYTICS: AnalyticsConfig = {
    // Google Analytics 4 Measurement ID (e.g., 'G-XXXXXXXXXX')
    ga4Id: "",
    // Umami Analytics configuration
    umami: umami
};
