import React from 'react';
import { cn } from '@/lib/utils';

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
          {
            'bg-navy text-white hover:bg-navy-light': variant === 'primary',
            'bg-gold text-navy font-semibold hover:bg-gold-light': variant === 'secondary',
            'border-2 border-navy text-navy hover:bg-navy hover:text-white': variant === 'outline',
            'hover:bg-neutral-gray/10 text-navy': variant === 'ghost',
            'h-9 px-4 py-2': size === 'sm',
            'h-11 px-6 py-2 text-base': size === 'md',
            'h-14 px-8 py-3 text-lg': size === 'lg',
          },
          className
        )}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button }