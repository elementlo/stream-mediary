// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// GitHub Pages project site: https://elementlo.github.io/stream-mediary/
// If a custom domain is bound later, set SITE to it and BASE to '' — the
// canonical/OG/sitemap URLs all derive from these two values.
const SITE = process.env.SITE ?? 'https://elementlo.github.io';
const BASE = process.env.BASE ?? '/stream-mediary';

export default defineConfig({
  site: SITE,
  base: BASE,
  trailingSlash: 'ignore',
  // Zero JS by default: Astro ships static HTML, which is what crawlers
  // (Baidu included) index best. No client framework is bundled.
  output: 'static',
  build: {
    inlineStylesheets: 'auto',
  },
  i18n: {
    locales: ['zh-CN', 'en'],
    defaultLocale: 'zh-CN',
    routing: {
      prefixDefaultLocale: false,
      redirectToDefaultLocale: false,
    },
  },
  integrations: [
    sitemap({
      i18n: {
        defaultLocale: 'zh-CN',
        locales: { 'zh-CN': 'zh-CN', en: 'en' },
      },
    }),
  ],
});
