<script setup lang="ts">
import NavBar from './view/components/NavBar.vue'
import Footer from './view/components/Footer.vue'
</script>

<template>
  <div class="flex flex-col min-h-screen bg-surface">
    <NavBar />
    
    <main class="flex-grow pt-[72px] pb-16 md:pb-0 flex flex-col">
      <router-view class="flex-grow" />
    </main>
    
    <Footer />
  </div>
</template>