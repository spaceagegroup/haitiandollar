import React from 'react';
import { SectionHeading } from '@/components/ui/SectionHeading';
import { Button } from '@/components/ui/Button';
import { FileText, Info, AlertTriangle } from 'lucide-react';
import Link from 'next/link';

export default function InvestorsPage() {
  return (
    <div className="pt-24 pb-16">
      <section className="py-16 bg-navy text-white text-center">
        <div className="container mx-auto px-4 md:px-8 max-w-3xl">
          <h1 className="text-4xl md:text-5xl font-bold font-heading mb-6">Investor Relations</h1>
          <p className="text-lg text-white/80 leading-relaxed">
            Transparent information for prospective and current stakeholders.
          </p>
        </div>
      </section>

      <section className="py-24 bg-white">
        <div className="container mx-auto px-4 md:px-8 max-w-4xl">
          {/* Whitepaper */}
          <div className="bg-neutral-offwhite p-8 md:p-12 rounded-2xl border border-neutral-gray/20 flex flex-col md:flex-row items-center justify-between gap-8 mb-16">
            <div>
              <h3 className="text-2xl font-bold font-heading text-navy mb-4">Official Whitepaper</h3>
              <p className="text-neutral-gray leading-relaxed mb-6">
                Read our comprehensive whitepaper to understand the technical architecture, tokenomics, and the long-term vision of the Haitian Dollar project.
              </p>
              <Button className="gap-2">
                <FileText className="w-5 h-5" />
                Download PDF
              </Button>
            </div>
            <div className="w-32 h-40 bg-white shadow-md border border-neutral-gray/10 flex-shrink-0 rounded flex items-center justify-center p-4 transform rotate-3">
               <div className="text-center">
                 <div className="w-12 h-1 bg-navy/20 mx-auto mb-2" />
                 <div className="w-16 h-1 bg-navy/20 mx-auto mb-4" />
                 <span className="font-heading font-bold text-navy text-sm">HTD Whitepaper</span>
               </div>
            </div>
          </div>

          {/* Exchange Status */}
          <div className="mb-16">
            <SectionHeading
              title="Exchange Listing Status"
              align="left"
              className="mb-8"
            />
            <div className="bg-white p-6 rounded-xl border border-neutral-gray/20 shadow-sm flex items-start gap-4">
              <div className="w-10 h-10 rounded-full bg-navy/10 flex items-center justify-center flex-shrink-0 mt-1">
                <Info className="w-5 h-5 text-navy" />
              </div>
              <div>
                <h4 className="font-bold text-navy mb-2">Current Status: Private / Delisted</h4>
                <p className="text-neutral-gray leading-relaxed text-sm">
                  The HTD token was previously listed on Dex-Trade. It is currently delisted as we refine our infrastructure and regulatory compliance strategy. We are actively working towards relisting on major decentralized and centralized exchanges in the future. Stay tuned to our <Link href="/news" className="text-navy font-semibold hover:underline">News</Link> page for official announcements.
                </p>
              </div>
            </div>
          </div>

          {/* Compliance & Risk */}
          <div>
            <SectionHeading
              title="Legal & Compliance"
              align="left"
              className="mb-8"
            />
            <div className="bg-white p-8 rounded-xl border border-htdred/20 shadow-sm relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-htdred" />
              <div className="flex items-center gap-3 mb-6">
                <AlertTriangle className="w-6 h-6 text-htdred" />
                <h4 className="font-bold font-heading text-navy text-xl">Important Disclaimer</h4>
              </div>
              <p className="text-neutral-gray leading-relaxed text-sm mb-6">
                Haitian Dollar Inc operates under SEC Regulation D/S exemptions. The information provided on this website does not constitute investment advice, financial advice, trading advice, or any other sort of advice.
              </p>
              <Link href="/legal">
                <Button variant="outline" size="sm">
                  View Full Disclaimers
                </Button>
              </Link>
            </div>
          </div>

        </div>
      </section>
    </div>
  );
}