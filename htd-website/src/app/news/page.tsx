import React from 'react';
import { SectionHeading } from '@/components/ui/SectionHeading';
import { MOCK_NEWS } from '@/lib/constants';
import { Calendar } from 'lucide-react';
import Link from 'next/link';

export default function NewsPage() {
  return (
    <div className="pt-24 pb-16">
      <section className="py-16 bg-navy text-white text-center">
        <div className="container mx-auto px-4 md:px-8 max-w-3xl">
          <h1 className="text-4xl md:text-5xl font-bold font-heading mb-6">News & Updates</h1>
          <p className="text-lg text-white/80 leading-relaxed">
            The latest announcements, press releases, and product updates from Haitian Dollar.
          </p>
        </div>
      </section>

      <section className="py-24 bg-neutral-offwhite min-h-[50vh]">
        <div className="container mx-auto px-4 md:px-8">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {MOCK_NEWS.map((post) => (
              <article key={post.id} className="bg-white rounded-xl overflow-hidden shadow-sm border border-neutral-gray/20 hover:shadow-md transition-shadow flex flex-col">
                <div className="h-48 bg-navy/5 relative border-b border-neutral-gray/10 flex items-center justify-center">
                  <span className="text-navy/30 font-heading font-bold text-2xl uppercase">{post.category}</span>
                </div>
                <div className="p-6 flex flex-col flex-grow">
                  <div className="flex items-center gap-4 mb-4 text-xs font-medium text-neutral-gray">
                    <span className="bg-navy/10 text-navy px-2.5 py-1 rounded-full uppercase tracking-wider">
                      {post.category}
                    </span>
                    <div className="flex items-center gap-1.5">
                      <Calendar className="w-3.5 h-3.5" />
                      {new Date(post.date).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
                    </div>
                  </div>
                  <h2 className="text-xl font-bold font-heading text-navy mb-3">
                    <Link href={`#`} className="hover:text-htdred transition-colors">
                      {post.title}
                    </Link>
                  </h2>
                  <p className="text-neutral-gray leading-relaxed flex-grow">
                    {post.excerpt}
                  </p>
                  <Link href={`#`} className="inline-flex mt-6 text-sm font-semibold text-navy hover:text-htdred transition-colors">
                    Read More &rarr;
                  </Link>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}