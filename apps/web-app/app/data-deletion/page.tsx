import React from "react";

export default function DataDeletion() {
  return (
    <main className="min-h-screen bg-[#0a0a0a] text-white py-16 px-6 font-sans relative overflow-hidden flex flex-col items-center justify-center">
      {/* Background gradients */}
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-red-600/20 rounded-full blur-[120px] opacity-30 mix-blend-screen pointer-events-none" />
      <div className="absolute inset-0 bg-[url('https://grainy-gradients.vercel.app/noise.svg')] opacity-20 pointer-events-none mix-blend-overlay"></div>

      <div className="max-w-2xl mx-auto relative z-10 w-full bg-[#111] border border-white/10 rounded-3xl p-8 md:p-12 shadow-2xl">
        <div className="w-16 h-16 bg-red-500/10 border border-red-500/20 rounded-full flex items-center justify-center mb-6">
          <svg className="w-8 h-8 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </div>
        
        <h1 className="text-3xl md:text-4xl font-extrabold tracking-tight mb-4 text-white">
          Data Deletion Request
        </h1>
        
        <div className="space-y-6 text-neutral-300 leading-relaxed mb-8">
          <p>
            At Execut, we respect your privacy and your right to control your personal data. You have the right to request the complete deletion of your account and all associated data.
          </p>
          <p>
            By proceeding, the following will occur:
          </p>
          <ul className="list-disc pl-6 space-y-2 text-neutral-400">
            <li>Your account will be permanently closed.</li>
            <li>All of your tracked habits, tasks, goals, and history will be securely erased.</li>
            <li>Your personal information (email, username, etc.) will be removed from our active systems.</li>
            <li>This action is irreversible.</li>
          </ul>
        </div>

        <div className="flex flex-col gap-4 border-t border-white/10 pt-8">
          <p className="text-sm text-neutral-500">
            To proceed, click the button below. This will open an email template addressed to our support team. Please ensure you send the request from the email address associated with your account.
          </p>
          <a 
            href="mailto:support@execut.pro?subject=Data%20Deletion%20Request&body=Please%20permanently%20delete%20my%20account%20and%20all%20associated%20data%20from%20Execut.%0A%0AMy%20account%20email%20is%3A%20" 
            className="inline-flex items-center justify-center bg-red-500 text-white px-6 py-4 rounded-xl font-bold hover:bg-red-600 transition-colors shadow-[0_0_15px_rgba(239,68,68,0.3)] w-full sm:w-auto"
          >
            Request Account Deletion
          </a>
        </div>
      </div>
    </main>
  );
}
