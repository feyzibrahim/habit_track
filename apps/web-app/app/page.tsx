"use client";

import { useState } from "react";

export default function Home() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;

    setStatus("loading");
    setErrorMessage("");

    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000";
      const response = await fetch(`${apiUrl}/waitlist`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || "Something went wrong");
      }

      setStatus("success");
    } catch (error: any) {
      setStatus("error");
      setErrorMessage(error.message || "Failed to join waitlist. Please try again.");
    }
  };

  return (
    <main className="min-h-screen bg-[#0a0a0a] text-white flex flex-col items-center justify-center relative overflow-hidden font-sans selection:bg-green-500/30">
      {/* Background gradients */}
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-green-600/30 rounded-full blur-[120px] opacity-50 mix-blend-screen pointer-events-none" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[600px] h-[600px] bg-emerald-600/20 rounded-full blur-[150px] opacity-50 mix-blend-screen pointer-events-none" />
      <div className="absolute inset-0 bg-[url('https://grainy-gradients.vercel.app/noise.svg')] opacity-20 pointer-events-none mix-blend-overlay"></div>

      <div className="z-10 w-full max-w-3xl px-6 flex flex-col items-center text-center">
        {/* Badge */}
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/5 border border-white/10 backdrop-blur-md mb-8 shadow-[0_0_15px_rgba(34,197,94,0.15)]">
          <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
          <span className="text-sm font-medium text-green-200 tracking-wide">Coming Soon</span>
        </div>

        {/* Hero Headline */}
        <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight mb-6 leading-[1.1]">
          Master your habits. <br className="hidden md:block" />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-green-400 via-emerald-500 to-teal-500">
            Forge your future.
          </span>
        </h1>

        {/* Description */}
        <p className="text-lg md:text-xl text-neutral-400 mb-12 max-w-2xl leading-relaxed">
          The ultimate productivity ecosystem designed to help you build lasting habits, track daily goals, and achieve your highest potential. Join the waitlist for exclusive early access.
        </p>

        {/* Waitlist Form */}
        {status === "success" ? (
          <div className="flex flex-col items-center bg-white/5 border border-white/10 rounded-2xl p-8 backdrop-blur-md animate-in fade-in slide-in-from-bottom-4 duration-700">
            <div className="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center mb-4">
              <svg className="w-8 h-8 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h3 className="text-2xl font-bold mb-2">You're on the list!</h3>
            <p className="text-neutral-400">We'll notify you when we're ready for you.</p>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="w-full max-w-md relative group">
            <div className="absolute -inset-1 bg-gradient-to-r from-green-500 to-teal-500 rounded-2xl blur opacity-25 group-hover:opacity-40 transition duration-500"></div>
            <div className="relative flex items-center bg-[#111] p-1.5 rounded-2xl border border-white/10 shadow-2xl">
              <input
                type="email"
                required
                placeholder="name@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={status === "loading"}
                className="flex-1 bg-transparent px-4 py-3 text-white placeholder-neutral-500 focus:outline-none disabled:opacity-50"
              />
              <button
                type="submit"
                disabled={status === "loading"}
                className="bg-white text-black px-6 py-3 rounded-xl font-semibold hover:bg-neutral-200 transition-colors disabled:opacity-70 flex items-center gap-2"
              >
                {status === "loading" ? (
                  <>
                    <svg className="animate-spin h-5 w-5 text-black" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Joining...
                  </>
                ) : (
                  "Join Waitlist"
                )}
              </button>
            </div>
            {status === "error" && (
              <p className="absolute -bottom-8 left-0 text-red-400 text-sm">{errorMessage}</p>
            )}
          </form>
        )}

        {/* Feature Highlights mini */}
        <div className="mt-24 grid grid-cols-1 md:grid-cols-3 gap-8 w-full max-w-4xl text-left border-t border-white/10 pt-12">
          {[
            { title: "Smart Tracking", desc: "Adaptive algorithms to keep you consistent." },
            { title: "Gamified XP", desc: "Level up your life as you complete tasks." },
            { title: "Deep Analytics", desc: "Understand your progress with visual insights." }
          ].map((feature, idx) => (
            <div key={idx} className="flex flex-col gap-2">
              <h4 className="text-white font-semibold flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-green-500"></div>
                {feature.title}
              </h4>
              <p className="text-sm text-neutral-500">{feature.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
