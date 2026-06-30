import React from "react";

export default function PrivacyPolicy() {
  return (
    <main className="min-h-screen bg-[#0a0a0a] text-white py-16 px-6 font-sans relative overflow-hidden">
      {/* Background gradients */}
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-green-600/30 rounded-full blur-[120px] opacity-30 mix-blend-screen pointer-events-none" />
      <div className="absolute inset-0 bg-[url('https://grainy-gradients.vercel.app/noise.svg')] opacity-20 pointer-events-none mix-blend-overlay"></div>

      <div className="max-w-4xl mx-auto relative z-10">
        <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight mb-6 text-transparent bg-clip-text bg-gradient-to-r from-green-400 via-emerald-500 to-teal-500">
          Privacy Policy
        </h1>
        <p className="text-neutral-400 mb-12">
          Last Updated: {new Date().toLocaleDateString("en-US", { year: 'numeric', month: 'long', day: 'numeric' })}
        </p>

        <div className="space-y-8 text-neutral-300 leading-relaxed">
          <section>
            <h2 className="text-2xl font-bold text-white mb-4">1. Introduction</h2>
            <p>
              Welcome to Execut ("we", "our", or "us"). We are committed to protecting your personal information and your right to privacy. This Privacy Policy applies to our mobile application, web application, and all related services (collectively, the "Services").
            </p>
            <p className="mt-4">
              This policy complies with applicable privacy laws, including the General Data Protection Regulation (GDPR) for our users in the European Union and applicable United States privacy laws (such as the CCPA).
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-bold text-white mb-4">2. Information We Collect</h2>
            <p className="mb-4">We collect personal information that you voluntarily provide to us when you register for the Services. The personal information we collect may include:</p>
            <ul className="list-disc pl-6 space-y-2">
              <li><strong className="text-white">Personal Information Provided by You:</strong> We collect names, email addresses, usernames, passwords, and other similar information.</li>
              <li><strong className="text-white">App Usage Data:</strong> Habits, tasks, goals, streaks, and other productivity data you input into Execut.</li>
              <li><strong className="text-white">Automatically Collected Information:</strong> Some information — such as your Internet Protocol (IP) address and/or browser and device characteristics — is collected automatically when you visit our Services.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-2xl font-bold text-white mb-4">3. How We Use Your Information</h2>
            <p className="mb-4">We use personal information collected via our Services for a variety of business purposes described below:</p>
            <ul className="list-disc pl-6 space-y-2">
              <li>To facilitate account creation and logon process.</li>
              <li>To provide and manage your Services, including tracking your habits and goals.</li>
              <li>To respond to user inquiries and offer support.</li>
              <li>To send administrative information to you.</li>
              <li>To fulfill and manage your orders and subscriptions.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-2xl font-bold text-white mb-4">4. Your Privacy Rights (GDPR & CCPA)</h2>
            <p className="mb-4">Depending on where you are located geographically, the applicable privacy law may mean you have certain rights regarding your personal information.</p>
            <p className="mb-4"><strong className="text-white">For EU Residents (GDPR):</strong> You have the right to request access to and obtain a copy of your personal information, request rectification or erasure, restrict processing, and if applicable, data portability.</p>
            <p><strong className="text-white">For US Residents (e.g., CCPA for California):</strong> You have the right to know what personal information is collected, request deletion of your personal data, and the right to non-discrimination for exercising your privacy rights. We do not sell your personal information.</p>
          </section>

          <section>
            <h2 className="text-2xl font-bold text-white mb-4">5. Data Security</h2>
            <p>
              We aim to protect your personal information through a system of organizational and technical security measures. However, no electronic transmission over the internet or information storage technology can be guaranteed to be 100% secure.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-bold text-white mb-4">6. Contact Us</h2>
            <p>
              If you have questions or comments about this policy, you may email us at support@execut.pro.
            </p>
          </section>
        </div>
      </div>
    </main>
  );
}
