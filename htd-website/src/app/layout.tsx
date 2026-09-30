import type { Metadata } from "next";
import { Inter, Montserrat } from "next/font/google";
import "./globals.css";
import Navbar from "@/components/layout/Navbar";
import Footer from "@/components/layout/Footer";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

const montserrat = Montserrat({
  subsets: ["latin"],
  variable: "--font-montserrat",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Haitian Dollar (HTD) | Blockchain Finance for Haiti",
  description:
    "Haitian Dollar (HTD) is a blockchain-based gateway providing financial inclusion for the unbanked and underbanked population in Haiti.",
  keywords: ["Haitian Dollar", "HTD", "blockchain", "Haiti", "fintech", "financial inclusion"],
  openGraph: {
    title: "Haitian Dollar (HTD)",
    description: "Bridging the gap: Blockchain finance for Haiti.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${inter.variable} ${montserrat.variable}`}>
      <body className="font-sans bg-neutral-offwhite text-neutral-charcoal antialiased flex flex-col min-h-screen">
        <Navbar />
        <main className="flex-grow">
          {children}
        </main>
        <Footer />
      </body>
    </html>
  );
}