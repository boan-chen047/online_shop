export interface CompressOptions {
  maxWidth?: number
  quality?: number
}

// 讀圖 → 若寬 > maxWidth 按比例縮 → 畫到 canvas → 輸出 JPEG blob
export async function compressImage(file: File, options: CompressOptions = {}): Promise<Blob> {
  const { maxWidth = 1600, quality = 0.85 } = options
  if (!file.type.startsWith('image/')) {
    throw new Error('只能上傳圖片檔。')
  }

  const dataUrl = await new Promise<string>((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result as string)
    reader.onerror = () => reject(new Error('讀取圖片失敗。'))
    reader.readAsDataURL(file)
  })

  const img = await new Promise<HTMLImageElement>((resolve, reject) => {
    const image = new Image()
    image.onload = () => resolve(image)
    image.onerror = () => reject(new Error('圖片格式無法解析。'))
    image.src = dataUrl
  })

  const scale = img.width > maxWidth ? maxWidth / img.width : 1
  const canvas = document.createElement('canvas')
  canvas.width = Math.round(img.width * scale)
  canvas.height = Math.round(img.height * scale)
  const ctx = canvas.getContext('2d')
  if (!ctx) {
    throw new Error('無法建立畫布。')
  }
  ctx.drawImage(img, 0, 0, canvas.width, canvas.height)

  const blob = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, 'image/jpeg', quality),
  )
  if (!blob) {
    throw new Error('圖片壓縮失敗。')
  }
  return blob
}
