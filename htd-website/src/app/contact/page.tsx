'use client';

import React from 'react';
import { SectionHeading } from '@/components/ui/SectionHeading';
import { Button } from '@/components/ui/Button';
import { Mail, MapPin } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';

const formSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters"),
  email: z.string().email("Invalid email address"),
  subject: z.string().min(5, "Subject must be at least 5 characters"),
  message: z.string().min(10, "Message must be at least 10 characters"),
});

type FormData = z.infer<typeof formSchema>;

export default function ContactPage() {
  const { register, handleSubmit, formState: { errors, isSubmitting }, reset } = useForm<FormData>({
    resolver: zodResolver(formSchema)
  });

  const onSubmit = async (data: FormData) => {
    // Mock submission
    await new Promise(resolve => setTimeout(resolve, 1000));
    console.log(data);
    alert("Message sent successfully!");
    reset();
  };

  return (
    <div className="pt-24 pb-16">
      <section className="py-16 bg-navy text-white text-center">
        <div className="container mx-auto px-4 md:px-8 max-w-3xl">
          <h1 className="text-4xl md:text-5xl font-bold font-heading mb-6">Contact Us</h1>
          <p className="text-lg text-white/80 leading-relaxed">
            Have questions about HTD? Our team is here to help.
          </p>
        </div>
      </section>

      <section className="py-24 bg-white">
        <div className="container mx-auto px-4 md:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 max-w-6xl mx-auto">
            {/* Contact Info */}
            <div>
              <SectionHeading
                title="Get in Touch"
                align="left"
                className="mb-8"
              />
              <p className="text-neutral-gray leading-relaxed mb-12">
                Whether you're an investor, a potential partner, or a user with questions about the platform, we'd love to hear from you. Fill out the form or reach out via our official channels below.
              </p>

              <div className="space-y-8">
                <div className="flex items-start gap-4">
                  <div className="w-12 h-12 rounded-full bg-navy/10 flex items-center justify-center flex-shrink-0">
                    <Mail className="w-6 h-6 text-navy" />
                  </div>
                  <div>
                    <h4 className="font-bold font-heading text-navy text-lg mb-1">Email Us</h4>
                    <p className="text-neutral-gray text-sm mb-1">For general inquiries and support.</p>
                    <a href="mailto:info@haitiandollar.com" className="text-navy font-semibold hover:underline">info@haitiandollar.com</a>
                  </div>
                </div>

                <div className="flex items-start gap-4">
                  <div className="w-12 h-12 rounded-full bg-navy/10 flex items-center justify-center flex-shrink-0">
                    <MapPin className="w-6 h-6 text-navy" />
                  </div>
                  <div>
                    <h4 className="font-bold font-heading text-navy text-lg mb-1">Corporate Address</h4>
                    <p className="text-neutral-gray text-sm mb-1">Haitian Dollar Inc.</p>
                    <address className="text-neutral-gray not-italic">
                      123 Blockchain Ave<br />
                      Tech District, HT 12345
                    </address>
                  </div>
                </div>
              </div>
            </div>

            {/* Contact Form */}
            <div className="bg-neutral-offwhite p-8 rounded-2xl border border-neutral-gray/20 shadow-sm">
              <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
                <div>
                  <label htmlFor="name" className="block text-sm font-semibold text-navy mb-2">Full Name</label>
                  <input
                    type="text"
                    id="name"
                    className="w-full px-4 py-3 rounded-lg border border-neutral-gray/30 focus:outline-none focus:ring-2 focus:ring-navy focus:border-transparent transition-all"
                    placeholder="John Doe"
                    {...register("name")}
                  />
                  {errors.name && <p className="text-htdred text-xs mt-1">{errors.name.message}</p>}
                </div>

                <div>
                  <label htmlFor="email" className="block text-sm font-semibold text-navy mb-2">Email Address</label>
                  <input
                    type="email"
                    id="email"
                    className="w-full px-4 py-3 rounded-lg border border-neutral-gray/30 focus:outline-none focus:ring-2 focus:ring-navy focus:border-transparent transition-all"
                    placeholder="john@example.com"
                    {...register("email")}
                  />
                  {errors.email && <p className="text-htdred text-xs mt-1">{errors.email.message}</p>}
                </div>

                <div>
                  <label htmlFor="subject" className="block text-sm font-semibold text-navy mb-2">Subject</label>
                  <input
                    type="text"
                    id="subject"
                    className="w-full px-4 py-3 rounded-lg border border-neutral-gray/30 focus:outline-none focus:ring-2 focus:ring-navy focus:border-transparent transition-all"
                    placeholder="How can we help?"
                    {...register("subject")}
                  />
                  {errors.subject && <p className="text-htdred text-xs mt-1">{errors.subject.message}</p>}
                </div>

                <div>
                  <label htmlFor="message" className="block text-sm font-semibold text-navy mb-2">Message</label>
                  <textarea
                    id="message"
                    rows={5}
                    className="w-full px-4 py-3 rounded-lg border border-neutral-gray/30 focus:outline-none focus:ring-2 focus:ring-navy focus:border-transparent transition-all resize-none"
                    placeholder="Your message here..."
                    {...register("message")}
                  />
                  {errors.message && <p className="text-htdred text-xs mt-1">{errors.message.message}</p>}
                </div>

                <Button type="submit" size="lg" className="w-full" disabled={isSubmitting}>
                  {isSubmitting ? "Sending..." : "Send Message"}
                </Button>
              </form>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}