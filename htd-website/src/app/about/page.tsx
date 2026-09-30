import React from 'react';
import { SectionHeading } from '@/components/ui/SectionHeading';
import { TEAM_MEMBERS } from '@/lib/constants';
import { Linkedin } from 'lucide-react';

export default function AboutPage() {
  return (
    <div className="pt-24 pb-16">
      {/* Hero Section */}
      <section className="py-16 bg-navy text-white">
        <div className="container mx-auto px-4 md:px-8 text-center max-w-4xl">
          <h1 className="text-4xl md:text-5xl font-bold font-heading mb-6">Our Mission</h1>
          <p className="text-lg md:text-xl text-white/80 leading-relaxed">
            Haitian Dollar Inc was founded with a singular vision: to democratize financial access in Haiti. We believe that blockchain technology can overcome the limitations of traditional banking, providing a secure, stable, and inclusive financial system for everyone.
          </p>
        </div>
      </section>

      {/* Team Section */}
      <section className="py-24 bg-neutral-offwhite">
        <div className="container mx-auto px-4 md:px-8">
          <SectionHeading
            eyebrow="Leadership"
            title="Meet Our Team"
            subtitle="Dedicated professionals bridging finance and technology."
          />
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mt-16 max-w-5xl mx-auto">
            {TEAM_MEMBERS.map((member, idx) => (
              <div key={idx} className="bg-white rounded-xl overflow-hidden shadow-sm border border-neutral-gray/20 text-center flex flex-col items-center p-8 hover:shadow-md transition-shadow">
                <div className="w-32 h-32 rounded-full bg-neutral-gray/20 mb-6 overflow-hidden">
                  {/* Placeholder for actual images */}
                  <div className="w-full h-full bg-navy/10 flex items-center justify-center">
                    <span className="text-navy text-2xl font-bold font-heading">{member.name.charAt(0)}</span>
                  </div>
                </div>
                <h3 className="text-xl font-bold font-heading text-navy mb-1">{member.name}</h3>
                <p className="text-htdred font-medium text-sm mb-4">{member.title}</p>
                <a href={member.linkedin} target="_blank" rel="noopener noreferrer" className="text-neutral-gray hover:text-navy transition-colors">
                  <Linkedin className="w-5 h-5" />
                </a>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Milestones Section */}
      <section className="py-24 bg-white">
        <div className="container mx-auto px-4 md:px-8 max-w-4xl">
          <SectionHeading
            eyebrow="Our Journey"
            title="Key Milestones"
            align="left"
          />
          <div className="space-y-8 mt-12 pl-4 md:pl-0">
            {[
              { year: "2022", title: "Project Inception", desc: "Initial research and development of the Haitian Dollar concept." },
              { year: "2023", title: "Incorporation & Whitepaper", desc: "Haitian Dollar Inc officially incorporated; V1 Whitepaper released." },
              { year: "2023", title: "SEC Exemptions Filed", desc: "Successfully filed for Regulation D/S exemptions." },
              { year: "2024", title: "Platform Development", desc: "Building the core blockchain infrastructure and mobile interfaces." }
            ].map((milestone, idx) => (
              <div key={idx} className="relative pl-8 md:pl-0 border-l-2 border-navy/20 md:border-none md:flex gap-8">
                <div className="absolute left-[-9px] top-0 w-4 h-4 rounded-full bg-htdred md:relative md:left-0 md:top-2 md:flex-shrink-0" />
                <div className="md:w-32 flex-shrink-0">
                  <span className="font-heading font-bold text-navy text-xl">{milestone.year}</span>
                </div>
                <div>
                  <h4 className="text-lg font-bold font-heading text-navy mb-2">{milestone.title}</h4>
                  <p className="text-neutral-gray">{milestone.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}