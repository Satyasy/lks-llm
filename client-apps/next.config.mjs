/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export', // Mengubah menjadi static HTML
  images: {
    unoptimized: true, // Wajib untuk static export agar tidak error saat build gambar
  },
};

export default nextConfig;