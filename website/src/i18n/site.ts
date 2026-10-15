// Single source of truth for site-wide SEO constants.

export const SITE_NAME = 'Mediary';
export const GITHUB_REPO = 'https://github.com/elementlo/stream-mediary';
export const EXTENSION_REPO =
  'https://github.com/elementlo/Mediary-Chrome-extension';
export const RELEASES_URL = `${GITHUB_REPO}/releases`;
export const LICENSE_URL = `${GITHUB_REPO}/blob/main/LICENSE`;

/** Absolute URL for a path, honoring the configured site + base. */
export function absoluteUrl(
  site: string,
  base: string,
  path = '',
): string {
  const cleanBase = base.replace(/\/$/, '');
  const cleanPath = path.startsWith('/') ? path : `/${path}`;
  return `${site}${cleanBase}${cleanPath === '/' ? '/' : cleanPath}`;
}
