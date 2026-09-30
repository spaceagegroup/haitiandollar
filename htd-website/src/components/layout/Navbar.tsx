'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { NAV_LINKS } from '@/lib/constants';
import { Button } from '@/components/ui/Button';
import { Menu, X } from 'lucide-react';
import { cn } from '@/lib/utils';
import { usePathname } from 'next/navigation';

const Navbar = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 10);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <header
      className={cn(
        "fixed top-0 w-full z-50 transition-all duration-300",
        isScrolled || pathname !== '/' ? "bg-white shadow-sm py-4" : "bg-transparent py-6"
      )}
    >
      <div className="container mx-auto px-4 md:px-8 flex justify-between items-center">
        <Link href="/" className="flex items-center gap-2 z-50">
          {/* Logo Placeholder */}
          <div className="w-10 h-10 bg-navy rounded-full flex items-center justify-center">
            <span className="text-white font-bold font-heading text-lg">HTD</span>
          </div>
          <span className={cn(
            "font-heading font-bold text-xl tracking-tight transition-colors",
            isScrolled || pathname !== '/' ? "text-navy" : "text-white"
          )}>
            Haitian Dollar
          </span>
        </Link>

        {/* Desktop Nav */}
        <nav className="hidden md:flex items-center gap-8">
          {NAV_LINKS.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className={cn(
                "font-medium text-sm transition-colors hover:text-htdred",
                isScrolled || pathname !== '/' ? "text-navy" : "text-white/90"
              )}
            >
              {link.label}
            </Link>
          ))}
          <Link href="/contact" tabIndex={-1}>
            <Button variant={isScrolled || pathname !== '/' ? "primary" : "secondary"}>
              Contact Us
            </Button>
          </Link>
        </nav>

        {/* Mobile Menu Toggle */}
        <button
          className={cn(
            "md:hidden z-50 p-2",
            isScrolled || pathname !== '/' || isMobileMenuOpen ? "text-navy" : "text-white"
          )}
          onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
        >
          {isMobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
        </button>

        {/* Mobile Nav Overlay */}
        <div
          className={cn(
            "fixed inset-0 bg-white z-40 flex flex-col justify-center items-center gap-8 transition-transform duration-300 md:hidden",
            isMobileMenuOpen ? "translate-x-0" : "translate-x-full"
          )}
        >
          {NAV_LINKS.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="text-2xl font-heading font-bold text-navy hover:text-htdred"
              onClick={() => setIsMobileMenuOpen(false)}
            >
              {link.label}
            </Link>
          ))}
          <Link href="/contact" tabIndex={-1} onClick={() => setIsMobileMenuOpen(false)}>
            <Button size="lg" className="mt-4">
              Contact Us
            </Button>
          </Link>
        </div>
      </div>
    </header>
  );
};

export default Navbar;