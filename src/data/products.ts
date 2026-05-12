export interface Product {
  id: number
  name: string
  category: 'snacks' | 'beverages' | 'daily' | 'electronics' | 'watches'
  price: number
  originalPrice?: number
  image: string
  description: string
  specs: Record<string, string>
  rating: number
  reviewCount: number
  tag?: string
}

const baseImages = {
  shoes: 'https://lh3.googleusercontent.com/aida-public/AB6AXuALcfjCgCF9-2VyM3uUGNcEEIRq_OfvKOzED6wXLvkyFXCWffyoiQjhGFjTFNj4SwmF3mHd3h3sQ8DXpUtH3niEU0ifHxHvXXCpXD4xa9OnY_fQIFvs-vZTY7ym2aDVs7OCP8BMI9_S-4brgIQvlmTSAIGwBAlUl25jFeemwv1Tq84a4ENLAEiKc6P1kaq-2lngx2KK01vpiByaQVVpvNwjF8RdMKAJPwkBtOAbiHkFKZjqm5dcnOUIjmZ8A4m6qsWuM_wrG8hBYkg',
  headphones: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3ivThTKfJYIMC1vA0z5rYigzHDnDIyDkL-EX27cbxZpdeydfbEqtoCkxTKh36sY8LbVKb7nQMyPOp9fZ_bzTG1I0M9zWBJjtAn7ZFZOATh_UAYeCxm4_vOj036h0t90UHbpK8gYtzk3JEUOvRflhXxYWLdcD9lsH5EC1NmEiK0WSDBW6X02ga-YtaIA_Ydklxs6DuyzZVJszdCdytoYQsQmhaEHFmjV5tB9R4STranc--cftVfb3P7kZ2m1LZxZwWJ0lA8Ehqd9I',
  lamp: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDqxooAJ9LDHZVzIiz1_ijaePfHKqSMW4XwxIp7mLcz8ZyfnF5c6YlyXtoTAiTVhHHXNliq8cXXQBTiwG9udrLWBhate1Iz7pyD7NnUMCOcZX9GdagzvE0kBGbTbEPCno4GxrIjF32N9NH7doMd7Hyh16TNdo0JVPEbtXs3alTH32544CRE-m-8gphmCMxVpu8PYe-SWx1cfrImh9a4gx9DxRRJAn7gAOxGlw0whAoLY3-1Tgyzai9rxh-r1z6E8M9J_RXvzulqSJw',
  amp: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAyNm_8fS3sjpNKYUQHPCxsB6kTsYhaSjWop7WY4kaAvIF9EHZ0LOM5DXR5N2qc-KY-3G8U6Yo5P33dV2eZLuTGq_eYYFBbuft1-UU77bF1Kk2O16ozz4XsmByQGj7jacFIdvBrPOoh8m5Ybv8kXQGynswbwSZzy5s1k6zeteBR1Qsi824p7uwE4iepNtWce6JqMDzZMVGAsrN0IdIn5rOajydFuMuNM_Sfj2XgRBDwof45vwi_9tnPoRvTEinw4jbe7-n5vNZULMI',
  charger: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCb2wn45CXHlez3vl4esofxIatMOp2nC7q-t5IMd0WdsNfQ7A-XOITngt_bEW5bUuMJHGRk-3lE4DhqaSSfn-f2pCM5vcT-Qjcz7ECY4ptnlIXq7-QGeBbQOK-AdTViUZ5TUBEb0QcVBo5m8WGZLFtE9734M95hnvzNzKQnNK6-8rHowJ1jBjDIimHnAHgDC_R63bZC42qcuBu8QJubvtftGykMpM-PUydfbDr7VOZbcWxicfuGVEU7UPKAkAlq_iAc6aBDwBx90vg'
}

export const products: Product[] = [
  {
    id: 1,
    name: 'Velocity Run Pro',
    category: 'daily',
    price: 120,
    originalPrice: 168,
    image: baseImages.shoes,
    description: 'A lightweight everyday trainer built for commuting, quick errands, and casual weekends.',
    specs: { Material: 'Breathable knit', Weight: '245 grams', Cushion: 'Dual-density foam', Fit: 'Regular' },
    rating: 4.7,
    reviewCount: 842,
    tag: 'Top Pick'
  },
  {
    id: 2,
    name: 'Acoustic Pure Over-Ear',
    category: 'electronics',
    price: 185,
    originalPrice: 249,
    image: baseImages.headphones,
    description: 'Wireless over-ear headphones with clean tuning, soft cushions, and long battery life.',
    specs: { Driver: '40mm Dynamic', Battery: '60 hours', Bluetooth: 'Version 5.3', Weight: '245 grams' },
    rating: 4.8,
    reviewCount: 1248,
    tag: 'New Arrival'
  },
  {
    id: 3,
    name: 'Lumina Desk Architect',
    category: 'daily',
    price: 79,
    image: baseImages.lamp,
    description: 'A compact desk lamp with adjustable brightness for study desks and work corners.',
    specs: { Brightness: '3 levels', Power: 'USB-C', Finish: 'Matte aluminum', Height: '42 cm' },
    rating: 4.6,
    reviewCount: 310
  },
  {
    id: 4,
    name: 'Sonic DAC External Amp',
    category: 'electronics',
    price: 129,
    image: baseImages.amp,
    description: 'Portable DAC and amplifier for cleaner desktop audio and low-noise headphone output.',
    specs: { Input: 'USB-C', Output: '3.5mm / 4.4mm', DAC: 'Hi-res 32-bit', Weight: '118 grams' },
    rating: 4.5,
    reviewCount: 276
  },
  {
    id: 5,
    name: 'Kinetic ChargePad Pro',
    category: 'electronics',
    price: 45,
    image: baseImages.charger,
    description: 'Slim wireless charging pad with a textured anti-slip surface and fast-charge support.',
    specs: { Output: '15W', Cable: 'USB-C included', Surface: 'Anti-slip silicone', Warranty: '1 year' },
    rating: 4.4,
    reviewCount: 198
  },
  {
    id: 6,
    name: 'Crisp Trail Mix Box',
    category: 'snacks',
    price: 18,
    image: baseImages.shoes,
    description: 'A balanced snack box with roasted nuts, dried fruit, and dark chocolate bites.',
    specs: { Weight: '480 grams', Packs: '12 single packs', Flavor: 'Sweet and salty', Storage: 'Room temperature' },
    rating: 4.3,
    reviewCount: 91
  },
  {
    id: 7,
    name: 'Citrus Spark Cooler',
    category: 'beverages',
    price: 24,
    image: baseImages.charger,
    description: 'Refreshing sparkling citrus drink for light gatherings and afternoon breaks.',
    specs: { Volume: '330ml x 12', Sugar: 'Low sugar', Flavor: 'Citrus', Serve: 'Chilled' },
    rating: 4.2,
    reviewCount: 76
  },
  {
    id: 8,
    name: 'Chronos Minimalist Series',
    category: 'watches',
    price: 249,
    originalPrice: 420,
    image: baseImages.amp,
    description: 'Minimal analog watch with a slim profile, brushed case, and clean dial.',
    specs: { Case: 'Stainless steel', Strap: 'Leather', Water: '5 ATM', Movement: 'Quartz' },
    rating: 4.9,
    reviewCount: 533,
    tag: '40% OFF'
  }
]

export const categoryNames: Record<Product['category'], string> = {
  snacks: '零食',
  beverages: '飲料',
  daily: '生活用品',
  electronics: '電子設備',
  watches: '手錶'
}

export function getProductById(id: number) {
  return products.find(product => product.id === id)
}
