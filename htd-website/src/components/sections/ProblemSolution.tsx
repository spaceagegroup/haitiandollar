import React from 'react';
import { SectionHeading } from '@/components/ui/SectionHeading';
import { CheckCircle2, XCircle } from 'lucide-react';

const ProblemSolution = () => {
  return (
    <section className="py-24 bg-neutral-offwhite">
      <div className="container mx-auto px-4 md:px-8">
        <SectionHeading
          eyebrow="The Current Landscape"
          title="Why Haiti Needs a Blockchain Solution"
          subtitle="Traditional banking infrastructure leaves millions without access to basic financial services, stunting economic growth and personal financial security."
        />

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 md:gap-16 mt-16">
          {/* Problem */}
          <div className="bg-white p-8 md:p-12 rounded-2xl shadow-sm border border-neutral-gray/10">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-12 h-12 rounded-full bg-htdred/10 flex items-center justify-center">
                <XCircle className="text-htdred w-6 h-6" />
              </div>
              <h3 className="text-2xl font-bold font-heading text-navy">The Challenge</h3>
            </div>
            <ul className="space-y-4">
              {[
                "Over 60% of the population remains unbanked or underbanked.",
                "High remittance fees limit the impact of diaspora contributions.",
                "Physical cash reliance exposes citizens to security risks.",
                "Currency volatility and inflation erode savings."
              ].map((item, idx) => (
                <li key={idx} className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-htdred mt-2.5 flex-shrink-0" />
                  <p className="text-neutral-gray leading-relaxed">{item}</p>
                </li>
              ))}
            </ul>
          </div>

          {/* Solution */}
          <div className="bg-navy p-8 md:p-12 rounded-2xl shadow-lg relative overflow-hidden">
            {/* Decorative background element */}
            <div className="absolute top-0 right-0 w-64 h-64 bg-gold/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/3" />

            <div className="flex items-center gap-4 mb-6 relative z-10">
              <div className="w-12 h-12 rounded-full bg-gold/20 flex items-center justify-center">
                <CheckCircle2 className="text-gold w-6 h-6" />
              </div>
              <h3 className="text-2xl font-bold font-heading text-white">Our Solution</h3>
            </div>
            <ul className="space-y-4 relative z-10">
              {[
                "Mobile-first wallet access requiring no traditional bank account.",
                "Near-zero fees for cross-border remittances via blockchain.",
                "Secure, immutable ledger protecting funds and transaction history.",
                "Pegged at 5 HTG = 1 HTD to provide a stable medium of exchange."
              ].map((item, idx) => (
                <li key={idx} className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-gold mt-2.5 flex-shrink-0" />
                  <p className="text-white/80 leading-relaxed">{item}</p>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
};

export default ProblemSolution;