'use client';

import React from 'react';
import { Button } from '@/components/ui/Button';
import Link from 'next/link';

const Hero = () => {
  return (
    <section className="relative min-h-[90vh] flex items-center justify-center bg-navy overflow-hidden">
      {/* Background elements */}
      <div className="absolute inset-0 z-0 opacity-20">
        <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] rounded-full bg-htdred blur-[120px]" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[60%] h-[60%] rounded-full bg-navy-light blur-[150px]" />
      </div>

      <div className="container mx-auto px-4 md:px-8 relative z-10 text-center mt-16">
        <h1 className="text-4xl md:text-6xl lg:text-7xl font-bold font-heading text-white mb-6 leading-tight animate-slide-up">
          Bridging the Gap:<br />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-gold to-white">
            Blockchain Finance for Haiti
          </span>
        </h1>

        <p className="text-lg md:text-xl text-white/80 max-w-2xl mx-auto mb-10 animate-fade-in" style={{ animationDelay: '0.2s', animationFillMode: 'both' }}>
          Haitian Dollar (HTD) provides financial inclusion for the unbanked and underbanked. Fast, secure, and pegged to the Haitian Gourde.
        </p>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 animate-slide-up" style={{ animationDelay: '0.4s', animationFillMode: 'both' }}>
          <Link href="/investors" tabIndex={-1}>
            <Button size="lg" variant="secondary" className="w-full sm:w-auto">
              Read Whitepaper
            </Button>
          </Link>
          <Link href="/contact" tabIndex={-1}>
            <Button size="lg" variant="outline" className="w-full sm:w-auto border-white/30 text-white hover:bg-white hover:text-navy">
              Contact Us
            </Button>
          </Link>
        </div>
      </div>
    </section>
  );
};

export default Hero;