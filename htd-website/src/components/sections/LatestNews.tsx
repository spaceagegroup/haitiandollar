import React from 'react';
import { SectionHeading } from '@/components/ui/SectionHeading';
import { MOCK_NEWS } from '@/lib/constants';
import Link from 'next/link';
import { ArrowRight, Calendar } from 'lucide-react';

const LatestNews = () => {
  return (
    <section className="py-24 bg-white">
      <div className="container mx-auto px-4 md:px-8">
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-6">
          <SectionHeading
            eyebrow="Updates"
            title="Latest News"
            align="left"
            className="mb-0"
          />
          <Link href="/news" className="group flex items-center gap-2 text-navy font-semibold hover:text-htdred transition-colors">
            View All News
            <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
          </Link>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {MOCK_NEWS.map((post) => (
            <Link key={post.id} href={`/news`} className="group flex flex-col h-full bg-neutral-offwhite rounded-xl overflow-hidden border border-neutral-gray/20 hover:shadow-lg transition-all">
              <div className="p-6 flex flex-col flex-grow">
                <div className="flex items-center gap-4 mb-4 text-xs font-medium text-neutral-gray">
                  <span className="bg-navy/10 text-navy px-2.5 py-1 rounded-full uppercase tracking-wider">
                    {post.category}
                  </span>
                  <div className="flex items-center gap-1.5">
                    <Calendar className="w-3.5 h-3.5" />
                    {new Date(post.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                  </div>
                </div>
                <h3 className="text-xl font-bold font-heading text-navy mb-3 group-hover:text-htdred transition-colors line-clamp-2">
                  {post.title}
                </h3>
                <p className="text-neutral-gray leading-relaxed flex-grow line-clamp-3">
                  {post.excerpt}
                </p>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
};

export default LatestNews;