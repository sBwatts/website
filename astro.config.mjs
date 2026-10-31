// @ts-check
import { defineConfig } from 'astro/config';
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';
import sitemap from '@astrojs/sitemap';

import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  markdown: {
    remarkPlugins: [remarkMath],
    rehypePlugins: [rehypeKatex],
  },
  build: {
    inlineStylesheets: 'always'
  },
  vite: {
    plugins: [tailwindcss()],
  },
  // Full address of the live site. Replace with your domain once DNS is set up.
  site: 'https://sethbwatts.com',
  // Only needed for a project repo (username.github.io/repo-name). Leave commented out
  // for username.github.io or a custom domain.
  // base: '/repo-name',
  integrations: [sitemap()],
});