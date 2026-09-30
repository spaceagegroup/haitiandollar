import React from 'react';
import Link from 'next/link';
import { NAV_LINKS } from '@/lib/constants';

const Footer = () => {
  return (
    <footer className="bg-navy-dark text-white pt-16 pb-8">
      <div className="container mx-auto px-4 md:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
          {/* Brand & Mission */}
          <div className="md:col-span-1">
            <Link href="/" className="flex items-center gap-2 mb-4">
              <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center">
                <span className="text-navy font-bold font-heading text-lg">HTD</span>
              </div>
              <span className="font-heading font-bold text-xl tracking-tight text-white">
                Haitian Dollar
              </span>
            </Link>
            <p className="text-white/70 text-sm leading-relaxed">
              Bridging the gap with blockchain finance. Providing financial inclusion and stability for the unbanked and underbanked population in Haiti.
            </p>
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="font-heading font-semibold text-lg mb-4 text-white">Quick Links</h4>
            <ul className="space-y-2">
              {NAV_LINKS.map((link) => (
                <li key={link.href}>
                  <Link href={link.href} className="text-white/70 hover:text-white text-sm transition-colors">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h4 className="font-heading font-semibold text-lg mb-4 text-white">Legal</h4>
            <ul className="space-y-2">
              <li>
                <Link href="/legal" className="text-white/70 hover:text-white text-sm transition-colors">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link href="/legal" className="text-white/70 hover:text-white text-sm transition-colors">
                  Terms of Service
                </Link>
              </li>
              <li>
                <Link href="/legal" className="text-white/70 hover:text-white text-sm transition-colors">
                  Compliance
                </Link>
              </li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h4 className="font-heading font-semibold text-lg mb-4 text-white">Contact</h4>
            <ul className="space-y-2 text-sm text-white/70">
              <li>info@haitiandollar.com</li>
              <li>123 Blockchain Ave</li>
              <li>Tech District, HT</li>
            </ul>
          </div>
        </div>

        <div className="border-t border-white/10 pt-8 text-center text-xs text-white/50 space-y-4">
          <p>
            &copy; {new Date().getFullYear()} Haitian Dollar Inc. All rights reserved.
          </p>
          <p className="max-w-4xl mx-auto uppercase tracking-wide">
            Disclaimer: Tokens may have no value. This website does not constitute financial advice. Haitian Dollar Inc operates under SEC Regulation D/S exemptions. Please read our full legal and risk disclosures on the Legal page before interacting with the HTD token.
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;