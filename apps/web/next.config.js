/** @type {import('next').NextConfig} */
const isGhPages = process.env.GITHUB_PAGES === 'true';

const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  ...(isGhPages
    ? {
        output: 'export',
        basePath: '/paynora',
        assetPrefix: '/paynora/',
        images: { unoptimized: true },
        trailingSlash: true,
      }
    : {}),
};

module.exports = nextConfig;
