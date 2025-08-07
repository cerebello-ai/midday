interface ImageLoaderParams {
  src: string;
  width: number;
  quality?: number;
}
const CDN_URL = "http://localhost:3000";
export default function imageLoader({
  src,
  width,
  quality = 80,
}: ImageLoaderParams): string {
  //return `https://midday.ai/cdn-cgi/image/width=${width},quality=${quality}/${src}`;
  return `${CDN_URL}/cdn-cgi/image/width=${width},quality=${quality}/${src}`;
}
