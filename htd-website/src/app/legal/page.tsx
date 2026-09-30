import React from 'react';
import { SectionHeading } from '@/components/ui/SectionHeading';

export default function LegalPage() {
  return (
    <div className="pt-24 pb-16">
      <section className="py-16 bg-navy text-white text-center">
        <div className="container mx-auto px-4 md:px-8 max-w-3xl">
          <h1 className="text-4xl md:text-5xl font-bold font-heading mb-6">Legal & Compliance</h1>
          <p className="text-lg text-white/80 leading-relaxed">
            Important regulatory disclosures, terms of service, and risk factors.
          </p>
        </div>
      </section>

      <section className="py-24 bg-white">
        <div className="container mx-auto px-4 md:px-8 max-w-4xl prose prose-navy prose-lg">
          <h2 className="text-2xl font-bold font-heading text-navy mb-4">Risk Disclosure & Disclaimers</h2>
          <p className="text-neutral-gray leading-relaxed mb-6">
            <strong>TOKENS MAY HAVE NO VALUE.</strong> The purchase of Haitian Dollar (HTD) tokens involves a high degree of risk. The information presented on this website does not constitute investment advice, financial advice, trading advice, or any other sort of advice and you should not treat any of the website's content as such.
          </p>
          <p className="text-neutral-gray leading-relaxed mb-6">
            Haitian Dollar Inc does not recommend that any cryptocurrency should be bought, sold, or held by you. Do conduct your own due diligence and consult your financial advisor before making any investment decisions.
          </p>

          <h2 className="text-2xl font-bold font-heading text-navy mb-4 mt-12">SEC Regulation D/S Exemption</h2>
          <p className="text-neutral-gray leading-relaxed mb-6">
            Haitian Dollar Inc operates under exemptions from registration under the U.S. Securities Act of 1933, specifically Regulation D for U.S. accredited investors and Regulation S for non-U.S. persons. The tokens have not been registered with the U.S. Securities and Exchange Commission (SEC) or any other regulatory authority.
          </p>

          <h2 className="text-2xl font-bold font-heading text-navy mb-4 mt-12">Terms of Service</h2>
          <p className="text-neutral-gray leading-relaxed mb-6">
            By accessing or using the Haitian Dollar website and services, you agree to be bound by our Terms of Service. These terms outline your rights and responsibilities when using our platform. We reserve the right to modify these terms at any time.
          </p>

          <h2 className="text-2xl font-bold font-heading text-navy mb-4 mt-12">Privacy Policy</h2>
          <p className="text-neutral-gray leading-relaxed mb-6">
            We are committed to protecting your privacy. Our Privacy Policy explains how we collect, use, and share your personal information. We employ industry-standard security measures to safeguard your data.
          </p>
        </div>
      </section>
    </div>
  );
}