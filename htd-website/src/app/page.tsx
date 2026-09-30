import React from 'react';
import Hero from '@/components/sections/Hero';
import ProblemSolution from '@/components/sections/ProblemSolution';
import HowItWorks from '@/components/sections/HowItWorks';
import Features from '@/components/sections/Features';
import TrustCompliance from '@/components/sections/TrustCompliance';
import LatestNews from '@/components/sections/LatestNews';

export default function Home() {
  return (
    <>
      <Hero />
      <ProblemSolution />
      <HowItWorks />
      <Features />
      <TrustCompliance />
      <LatestNews />
    </>
  );
}