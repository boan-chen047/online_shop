export interface NewsItem {
  id: number
  tag: string
  date: string
  dateRaw: string
  title: string
  description: string
  image: string
  alt: string
  readTime: string
  content: {
    intro: string
    sectionTitle: string
    sectionBody1: string
    quote: {
      text: string
      author: string
    }
    sectionBody2: string
  }
}

const baseNews: Omit<NewsItem, 'id'>[] = [
  {
    tag: 'Global',
    date: 'October 24, 2024',
    dateRaw: '2024-10-24',
    title: 'Kinetic Announces Global Expansion into Emerging Digital Markets',
    description: 'A strategic initiative to empower over 50,000 new enterprise operators with refined commerce tools by Q4 2025.',
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCGjQCP61VxUmioEYuzMy_f7I9md4BcSeMlOMbQL6G3y1VIUZV0rb0to-g_AK1fpiyfJM2fAQ1XTCOP85PLX00pE4xdPfYOcT1yUicngaBiRwCJOMOCGTdOSV5NnZ147f7w0f3aUmG5b_6KJEiFDEQBJl0pe8cn29AL0XYi-KDMcr0VTfpNyKTBOcRmw7QGQq3X0FaWys_jUG75QmlU59skO39G1NImwC9uMpcBPvosEt_vCv2_j_toynCy15ZdCbdtfiTK-_GGtkM',
    alt: 'Global Expansion',
    readTime: '6 min read',
    content: {
      intro: 'Kinetic is expanding its commerce infrastructure across new markets with a focus on faster fulfillment and stronger merchant operations.',
      sectionTitle: 'Bridging the Infrastructure Gap',
      sectionBody1: 'The effort combines routing tools, local inventory planning, and partner enablement to reduce friction for small and mid-sized sellers.',
      quote: {
        text: '"Expansion is about the structural integrity of the service we provide to every merchant."',
        author: 'Elena Rossi, Chief Operating Officer'
      },
      sectionBody2: 'The company will continue investing in local teams, practical automation, and a more reliable operator experience through 2025.'
    }
  },
  {
    tag: 'Partnership',
    date: 'October 20, 2024',
    dateRaw: '2024-10-20',
    title: 'Strategic Partnership with Vector Design Systems',
    description: 'Merging architectural precision with modern commerce tools to redefine how storefronts are maintained globally.',
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDM_uBSVfiqkC9r6dVKtKhk6ipS_KIJ1Ngk-ukj6OZ9rMiIC2o-dNRVf619W7MiobJLoUEl2zdFcDEdYawmKnKkdJ1HkXUY1XrPWX4LPu1X7WUVWX9m2pf0LbWY4bYIQVjMAWGExc0g01PmJF2W1Rp7ohlq4In7hO3mS7XMRsAtKGC5kQC6XTten353y-OlLB52phCEvux3wTwhEETSI2mJ0laepi1QVRgTVsLXyW81vbiEgulUtfoVi9d10ydDu-vszp_Svh5fTx4',
    alt: 'Strategic Partnership',
    readTime: '4 min read',
    content: {
      intro: 'Kinetic and Vector Design Systems are building a shared workflow for richer, easier-to-maintain online storefronts.',
      sectionTitle: 'A Shared Design Language',
      sectionBody1: 'The partnership focuses on reusable interface patterns, cleaner handoff, and better support for growing commerce teams.',
      quote: {
        text: '"Good commerce software should feel composed, reliable, and fast to adapt."',
        author: 'Marcus Lee, Product Director'
      },
      sectionBody2: 'Early pilots will focus on catalog operations, merchandising pages, and storefront analytics.'
    }
  },
  {
    tag: 'Product',
    date: 'October 15, 2024',
    dateRaw: '2024-10-15',
    title: 'Kinetic v4.2: The Architectural Engine Released',
    description: 'Introducing enhanced grid snapping for enterprise dashboard layouts and faster operator workflows.',
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDhuKogbbrStjikxRIqgtHBb6lTgD7qD46-A-p4sDP9-mVMtJYA7siFi0xITatpnl6eXzgI8PXaTws96INcenz2_TQKd2KLI5u7zmqkzz_lijym1vwvmsy_a1SDBHmvmHv1ibJTl1n25fQ8hjmGcuCOnShGyDR2DoYJN5ASxUb-l-uF89jtOiNPqCgiz5lsN3ir463yEvCninQqfnKKcq5nLL0rxsMNBa4ezbsFJOVPRE3pkaskqT5fiRKDxh3dgTj9s6nX_8wXzmo',
    alt: 'Product Update',
    readTime: '5 min read',
    content: {
      intro: 'Version 4.2 brings interface and workflow updates aimed at making daily operations faster and less error-prone.',
      sectionTitle: 'Built for Repeated Work',
      sectionBody1: 'The release improves grid controls, batch editing, and visual consistency across commerce dashboards.',
      quote: {
        text: '"Operators deserve tools that stay calm even when the workload is heavy."',
        author: 'Iris Chen, Engineering Lead'
      },
      sectionBody2: 'The update is available now for all supported workspaces.'
    }
  },
  {
    tag: 'Culture',
    date: 'October 08, 2024',
    dateRaw: '2024-10-08',
    title: 'Sustainability Report 2024 Now Available',
    description: 'How Kinetic is reducing operational waste and optimizing infrastructure for future growth.',
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBexMkgMId63sVOsiSHUZHxfx39SIOOz-JgE7kqOpuThNwUYl_-xNkTXcCGMuV7C9OOEVX6gpA1-5Zo7luKpdg5oIvD5S36FH4JTvUFNT7l4KYj5w7cGcloddJHCAdeaUrV-VUejb__0o6ldws5spdGVqMbjeTPPaQxsFA7FpCoxBjy36ghdar7qKgECrcct0P3F0uLGZyMPzetxQBz4DBQIWRzQnOGL31F499g8cBXCmvEuRGn-Szj5R6tcAA-uOkBRknUFFs_Xfc',
    alt: 'Sustainability',
    readTime: '7 min read',
    content: {
      intro: 'The 2024 report outlines how Kinetic is reducing waste across packaging, fulfillment, and digital operations.',
      sectionTitle: 'Practical Sustainability',
      sectionBody1: 'The team is prioritizing measurable changes: lighter packaging, better routing, and fewer redundant operational steps.',
      quote: {
        text: '"Sustainability improves when good defaults make waste harder to create."',
        author: 'Nadia Park, Operations Strategy'
      },
      sectionBody2: 'Kinetic will publish quarterly progress updates as these programs expand.'
    }
  }
]

export const newsItems: NewsItem[] = Array.from({ length: 15 }).map((_, index) => {
  const base = baseNews[index % baseNews.length]

  return {
    ...base,
    id: index + 1,
    title: index >= baseNews.length ? `${base.title} (Part ${Math.floor(index / baseNews.length) + 1})` : base.title
  }
})

export function getNewsById(id: number) {
  return newsItems.find(item => item.id === id)
}
