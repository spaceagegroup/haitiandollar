import React from 'react';
import { SectionHeading } from '@/components/ui/SectionHeading';
import { HOW_IT_WORKS_STEPS } from '@/lib/constants';
import * as Icons from 'lucide-react';

const HowItWorks = () => {
  return (
    <section className="py-24 bg-white">
      <div className="container mx-auto px-4 md:px-8">
        <SectionHeading
          eyebrow="The Process"
          title="How It Works"
          subtitle="A seamless ecosystem designed for accessibility and ease of use."
        />

        <div className="grid grid-cols-1 md:grid-cols-3 gap-12 relative mt-16">
          {/* Connecting Line for Desktop */}
          <div className="hidden md:block absolute top-12 left-1/6 right-1/6 h-[2px] bg-neutral-gray/20 -z-10" />

          {HOW_IT_WORKS_STEPS.map((step, idx) => {
            const Icon = (Icons as any)[step.icon];
            return (
              <div key={idx} className="relative flex flex-col items-center text-center">
                <div className="w-24 h-24 rounded-full bg-neutral-offwhite border-4 border-white shadow-sm flex items-center justify-center mb-6 relative z-10">
                  <Icon className="w-10 h-10 text-navy" />
                  <div className="absolute -top-2 -right-2 w-8 h-8 rounded-full bg-gold text-navy font-bold flex items-center justify-center text-sm shadow-sm">
                    {step.step}
                  </div>
                </div>
                <h3 className="text-xl font-bold font-heading text-navy mb-3">{step.title}</h3>
                <p className="text-neutral-gray leading-relaxed max-w-sm">{step.description}</p>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};

export default HowItWorks;