import React from 'react';
import { SectionHeading } from '@/components/ui/SectionHeading';
import { Card } from '@/components/ui/Card';
import { FEATURES_DATA } from '@/lib/constants';

const Features = () => {
  return (
    <section className="py-24 bg-neutral-offwhite">
      <div className="container mx-auto px-4 md:px-8">
        <SectionHeading
          eyebrow="Key Features"
          title="Designed for Stability and Scale"
          subtitle="The HTD token leverages modern blockchain technology to deliver a robust financial tool."
        />

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mt-16">
          {FEATURES_DATA.map((feature, idx) => (
            <Card
              key={idx}
              title={feature.title}
              description={feature.description}
              iconName={feature.icon}
            />
          ))}
        </div>
      </div>
    </section>
  );
};

export default Features;