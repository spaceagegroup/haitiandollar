import React from 'react';
import Link from 'next/link';
import { ShieldCheck, ArrowRight } from 'lucide-react';

const TrustCompliance = () => {
  return (
    <section className="py-20 bg-navy text-white border-t border-white/10">
      <div className="container mx-auto px-4 md:px-8">
        <div className="flex flex-col md:flex-row items-center justify-between gap-8 md:gap-16">
          <div className="flex items-start gap-6 max-w-2xl">
            <div className="w-14 h-14 rounded-full bg-gold/20 flex-shrink-0 flex items-center justify-center">
              <ShieldCheck className="w-8 h-8 text-gold" />
            </div>
            <div>
              <h3 className="text-2xl font-bold font-heading mb-3">Trust & Compliance</h3>
              <p className="text-white/80 leading-relaxed">
                Haitian Dollar Inc operates under strict regulatory frameworks, including SEC Regulation D/S exemptions. We prioritize transparency, security, and legal compliance to ensure a safe ecosystem for our users.
              </p>
            </div>
          </div>
          <Link href="/legal" className="group flex items-center gap-2 text-gold font-semibold hover:text-gold-light transition-colors whitespace-nowrap">
            View Legal Documentation
            <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
          </Link>
        </div>
      </div>
    </section>
  );
};

export default TrustCompliance;