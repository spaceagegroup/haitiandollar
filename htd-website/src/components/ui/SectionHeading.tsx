import React from 'react';
import { cn } from '@/lib/utils';

interface SectionHeadingProps {
  eyebrow?: string;
  title: string;
  subtitle?: string;
  align?: 'left' | 'center';
  className?: string;
}

export const SectionHeading: React.FC<SectionHeadingProps> = ({ eyebrow, title, subtitle, align = 'center', className }) => {
  return (
    <div className={cn("mb-12", align === 'center' ? 'text-center' : 'text-left', className)}>
      {eyebrow && (
        <span className="text-htdred font-semibold tracking-wider uppercase text-sm mb-2 block">
          {eyebrow}
        </span>
      )}
      <h2 className="text-3xl md:text-4xl font-bold font-heading text-navy mb-4">
        {title}
      </h2>
      {subtitle && (
        <p className={cn("text-lg text-neutral-gray max-w-2xl", align === 'center' ? 'mx-auto' : '')}>
          {subtitle}
        </p>
      )}
    </div>
  );
};