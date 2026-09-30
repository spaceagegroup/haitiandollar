import React from 'react';
import { SectionHeading } from '@/components/ui/SectionHeading';
import { ArrowRightLeft, ShieldCheck, Zap } from 'lucide-react';

export default function HTDPage() {
  return (
    <div className="pt-24 pb-16">
      {/* Hero Section */}
      <section className="py-16 bg-navy text-white text-center">
        <div className="container mx-auto px-4 md:px-8 max-w-3xl">
          <h1 className="text-4xl md:text-5xl font-bold font-heading mb-6">The Haitian Dollar (HTD)</h1>
          <p className="text-lg text-white/80 leading-relaxed">
            A stable, secure, and accessible digital asset designed to empower the Haitian economy.
          </p>
        </div>
      </section>

      {/* What is HTD & The Peg */}
      <section className="py-24 bg-white">
        <div className="container mx-auto px-4 md:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
            <div>
              <SectionHeading
                eyebrow="The Token"
                title="What is HTD?"
                align="left"
                className="mb-6"
              />
              <p className="text-neutral-gray leading-relaxed mb-6">
                The Haitian Dollar (HTD) is a blockchain-based cryptocurrency built specifically for the Haitian market. Unlike volatile cryptocurrencies, HTD is designed as a stable medium of exchange, making it ideal for daily transactions, remittances, and secure savings.
              </p>
              <ul className="space-y-4">
                {[
                  { icon: ShieldCheck, text: "Immutable and secure ledger" },
                  { icon: Zap, text: "Lightning-fast transaction times" },
                  { icon: ArrowRightLeft, text: "Seamless conversion to local currency" }
                ].map((item, idx) => (
                  <li key={idx} className="flex items-center gap-3 text-navy font-medium">
                    <div className="w-8 h-8 rounded-full bg-navy/5 flex items-center justify-center">
                      <item.icon className="w-4 h-4 text-navy" />
                    </div>
                    {item.text}
                  </li>
                ))}
              </ul>
            </div>

            <div className="bg-neutral-offwhite p-8 md:p-12 rounded-2xl border border-neutral-gray/20 text-center relative overflow-hidden shadow-sm">
              <div className="absolute top-0 right-0 w-32 h-32 bg-htdred/10 rounded-full blur-2xl -translate-y-1/2 translate-x-1/2" />
              <h3 className="text-2xl font-bold font-heading text-navy mb-8 relative z-10">The 5:1 Fixed Peg</h3>

              <div className="flex flex-col sm:flex-row items-center justify-center gap-6 relative z-10">
                <div className="bg-white p-6 rounded-xl shadow-sm border border-neutral-gray/10 w-40">
                  <span className="block text-4xl font-bold font-heading text-navy mb-2">5</span>
                  <span className="text-sm font-semibold text-neutral-gray uppercase tracking-wider">HTG</span>
                  <span className="block text-xs text-neutral-gray mt-1">Haitian Gourdes</span>
                </div>

                <div className="text-htdred font-bold text-2xl">
                  =
                </div>

                <div className="bg-navy p-6 rounded-xl shadow-md w-40">
                  <span className="block text-4xl font-bold font-heading text-white mb-2">1</span>
                  <span className="text-sm font-semibold text-gold uppercase tracking-wider">HTD</span>
                  <span className="block text-xs text-white/70 mt-1">Haitian Dollar</span>
                </div>
              </div>

              <p className="mt-8 text-neutral-gray text-sm leading-relaxed relative z-10">
                This fixed peg ensures stability, protecting users from the volatility typically associated with digital assets, providing a reliable store of value.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Use Cases */}
      <section className="py-24 bg-neutral-offwhite">
        <div className="container mx-auto px-4 md:px-8">
          <SectionHeading
            eyebrow="Applications"
            title="Real-World Use Cases"
            subtitle="How HTD is transforming daily financial activities."
          />
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mt-16">
            {[
              { title: "Remittances", desc: "Send money back home from anywhere in the world with near-zero fees and instant settlement." },
              { title: "Everyday Payments", desc: "Pay merchants for goods and services directly from a mobile device without needing physical cash." },
              { title: "Secure Savings", desc: "Store value securely on the blockchain, protected from physical theft and local market fluctuations." }
            ].map((useCase, idx) => (
              <div key={idx} className="bg-white p-8 rounded-xl shadow-sm border border-neutral-gray/10">
                <h4 className="text-xl font-bold font-heading text-navy mb-4">{useCase.title}</h4>
                <p className="text-neutral-gray leading-relaxed">{useCase.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}