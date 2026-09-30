import React from 'react';
import { cn } from '@/lib/utils';
import * as Icons from 'lucide-react';

interface CardProps {
  title: string;
  description: string;
  iconName?: string;
  className?: string;
}

export const Card: React.FC<CardProps> = ({ title, description, iconName, className }) => {
  const Icon = iconName ? (Icons as any)[iconName] : null;

  return (
    <div className={cn("p-6 rounded-xl bg-white shadow-sm border border-neutral-gray/20 hover:shadow-md transition-shadow", className)}>
      {Icon && (
        <div className="w-12 h-12 rounded-lg bg-navy/5 flex items-center justify-center mb-4">
          <Icon className="w-6 h-6 text-navy" />
        </div>
      )}
      <h3 className="text-xl font-bold font-heading text-navy mb-2">{title}</h3>
      <p className="text-neutral-gray leading-relaxed">{description}</p>
    </div>
  );
};