import { useAuth } from "../AuthProvider";
import { Link, useNavigate } from "react-router-dom";
import GridDistortion from "../react-bits/gridDistortion";
import bg_img from "../assets/blr-infra-1.png";
import TextType from "../react-bits/TextType";
import Footer from "./Footer";
import Navbar from "./Navbar";
import report from "../assets/reporticon.png";
import analysis from "../assets/analysisicon.png";
import community from "../assets/communityicon.jpg";
import { TrendingUp, Shield, Users, ArrowRight, Zap, CheckCircle, ChevronRight, ChevronDown,Clock } from "lucide-react";

const Landing = () => {
  const { isAuthenticated } = useAuth();
  const navigate = useNavigate();

  const handleGetStarted = () => {
    navigate('/login');
  };

  return (
    <div className="relative flex flex-col min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 overflow-x-hidden">
      <Navbar />

      {/* Decorative background elements */}
      <div className="fixed top-20 right-10 w-72 h-72 bg-blue-300 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob"></div>
      <div className="fixed top-40 left-10 w-72 h-72 bg-purple-300 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob animation-delay-2000"></div>
      <div className="fixed bottom-20 left-1/2 w-72 h-72 bg-indigo-300 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob animation-delay-4000"></div>

      <div
        className="fixed inset-0 -z-10 overflow-hidden opacity-15"
        style={{
          backgroundImage: `url(${bg_img})`,
          backgroundSize: "cover",
          backgroundRepeat: "no-repeat",
          backgroundPosition: "top center",
        }}
      >
        <div className="fixed inset-0 w-full h-full pointer-events-none">
          <GridDistortion
            imageSrc={bg_img}
            grid={80}
            mouse={0.03}
            strength={0.15}
            relaxation={0.9}
          />
        </div>

        <img
          src={bg_img}
          alt="background"
          className="absolute inset-0 w-full h-full object-cover object-top md:hidden"
        />
      </div>

      <main className="flex-grow container mx-auto px-4 sm:px-6 md:px-8 lg:px-12 py-12 md:py-20 text-center flex flex-col gap-8 md:gap-10 justify-center pt-6 md:pt-12">
        {/* Hero Section */}
        <div className="relative">
          <h1 className="text-4xl sm:text-5xl md:text-6xl lg:text-8xl font-black mt-15 md:mt-12 leading-tight lg:mt-12 text-gray-900 mb-4">
            Welcome to <span className="relative inline-block">
              <span className="relative z-10">NagrikMitra</span>
              <span className="absolute bottom-2 left-0 w-full h-4 bg-yellow-300 -skew-y-1 -z-0"></span>
            </span>
          </h1>
          <p className="text-xl sm:text-2xl md:text-3xl text-gray-600 font-semibold max-w-3xl mx-auto">
            Your Voice. Your City. Your Impact.
          </p>
        </div>

        {/* Updated TextType styling for visibility: Dark background for white text */}
        <div className="font-bold text-lg sm:text-xl md:text-2xl lg:text-3xl px-6 md:px-8 text-white bg-indigo-900/90 backdrop-blur-md py-3 rounded-full max-w-fit mx-auto shadow-xl border-2 border-indigo-200/50">
          <TextType
            text={[
              "Report issues instantly ⚡",
              "Make Bangalore cleaner 🌿",
              "Your voice matters 📢",
              "Help shape your city 🏙️",
              "Every complaint counts 📊",
              "Small actions, big impact 💪",
              "Together for a better Bangalore 🤝",
              "Be the change you wish to see ✨",
              "Happy citizens, happy city 😊",
              "Track complaints like a pro 🎯",
              "No pothole too small 🚧",
              "Make noise, get results 🔔",
            ]}
            typingSpeed={50}
            pauseDuration={1500}
            showCursor={true}
            cursorCharacter="|"
          />
        </div>

        {!isAuthenticated && (
          <div className="flex flex-col sm:flex-row justify-center gap-4 items-center">
            <button
              onClick={handleGetStarted}
              className="group relative bg-gradient-to-r from-indigo-600 to-purple-600 font-bold cursor-pointer text-white px-8 sm:px-10 md:px-12 py-3 sm:py-4 rounded-full hover:scale-105 transition-all duration-300 text-lg sm:text-xl md:text-2xl shadow-2xl hover:shadow-indigo-500/50 flex items-center gap-2"
            >
              Get Started
              <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </button>
            <div className="flex items-center gap-2 text-gray-600 text-sm">
              <CheckCircle className="w-4 h-4 text-green-600" />
              <span>Free forever • No credit card required</span>
            </div>
          </div>
        )}

        {/* Steps Section (How It Works) */}
        <section className="mt-8 md:mt-12 w-full">
          <div className="mb-8 md:mb-10">
            <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-gray-900 mb-3">
              How It <span className="relative inline-block">
              <span className="relative z-10">Works</span>
              <span className="absolute -bottom-0.5 left-0 w-full h-2 bg-yellow-300"></span>
            </span>
            </h2>
            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
              Three simple steps to make a difference in your community
            </p>
          </div>

          <div className="flex flex-col lg:flex-row items-center justify-center gap-4 lg:gap-2 max-w-7xl mx-auto px-2">
            
            {/* STEP 1 */}
            <div className="flex-1 w-full">
              {isAuthenticated ? (
                <Link to="/report" className="relative block group h-full">
                  <div className="absolute inset-0 bg-gradient-to-br from-blue-400 to-indigo-500 opacity-0 group-hover:opacity-100 rounded-3xl blur-xl transition-all duration-500"></div>
                  <div className="relative bg-white border-2 border-blue-200 hover:border-blue-400 shadow-xl rounded-3xl transition-all duration-300 h-full flex flex-col">
                    <div className="p-6 sm:p-7 md:p-9 flex flex-col items-center text-center h-full">
                      <div className="relative mb-4">
                        <div className="absolute inset-0 bg-blue-400 rounded-full blur-lg opacity-30 group-hover:opacity-50 transition-opacity"></div>
                        <img src={report} alt="Report" className="relative w-16 h-16 sm:w-20 sm:h-20 rounded-full border-4 border-blue-100 shadow-lg" />
                      </div>
                      <div className="absolute top-4 left-4 bg-blue-600 text-white text-xs font-bold px-3 py-1 rounded-full">STEP 1</div>
                      <h3 className="text-2xl sm:text-3xl font-black mb-3 text-gray-900">Report Issues</h3>
                      <p className="text-base text-gray-600 leading-relaxed flex-grow">Easily report civic problems with photos and location details in seconds.</p>
                      <div className="mt-4 flex items-center text-blue-600 font-semibold group-hover:translate-x-2 transition-transform">
                        Start Reporting <ArrowRight className="w-4 h-4 ml-2" />
                      </div>
                    </div>
                  </div>
                </Link>
              ) : (
                <div onClick={handleGetStarted} className="relative block group h-full cursor-pointer">
                  <div className="absolute inset-0 bg-gradient-to-br from-blue-400 to-indigo-500 opacity-0 group-hover:opacity-100 rounded-3xl blur-xl transition-all duration-500"></div>
                  <div className="relative bg-white border-2 border-blue-200 hover:border-blue-400 shadow-xl rounded-3xl transition-all duration-300 h-full flex flex-col">
                    <div className="p-6 sm:p-7 md:p-9 flex flex-col items-center text-center h-full">
                      <div className="relative mb-4">
                        <div className="absolute inset-0 bg-blue-400 rounded-full blur-lg opacity-30 group-hover:opacity-50 transition-opacity"></div>
                        <img src={report} alt="Report" className="relative w-16 h-16 sm:w-20 sm:h-20 rounded-full border-4 border-blue-100 shadow-lg" />
                      </div>
                      <div className="absolute top-4 left-4 bg-blue-600 text-white text-xs font-bold px-3 py-1 rounded-full">STEP 1</div>
                      <h3 className="text-2xl sm:text-3xl font-black mb-3 text-gray-900">Report Issues</h3>
                      <p className="text-base text-gray-600 leading-relaxed flex-grow">Login required to report issues. Click to sign in and get started.</p>
                      <div className="mt-4 flex items-center text-blue-600 font-semibold group-hover:translate-x-2 transition-transform">
                        Get Started <ArrowRight className="w-4 h-4 ml-2" />
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Stylish Directional Arrow 1 */}
            <div className="flex items-center justify-center px-4 py-2">
              <div className="relative">
                {/* Mobile: Down Arrow */}
                <div className="lg:hidden flex flex-col items-center gap-1 text-indigo-400">
                  <div className="w-1 h-8 bg-gradient-to-b from-indigo-400 to-purple-400 rounded-full"></div>
                  <ChevronDown className="w-10 h-10 animate-bounce" strokeWidth={3} />
                  <div className="w-1 h-8 bg-gradient-to-b from-purple-400 to-indigo-400 rounded-full"></div>
                </div>
                
                {/* Desktop: Right Arrow */}
                <div className="hidden lg:flex items-center gap-1 text-indigo-400">
                  <div className="h-1 w-12 bg-gradient-to-r from-indigo-400 to-purple-400 rounded-full"></div>
                  <ChevronRight className="w-12 h-12 animate-pulse" strokeWidth={3} />
                  <div className="h-1 w-12 bg-gradient-to-r from-purple-400 to-indigo-400 rounded-full"></div>
                </div>
              </div>
            </div>

            {/* STEP 2 */}
            <div className="flex-1 w-full">
              <Link to="/track" className="relative block group h-full">
                <div className="absolute inset-0 bg-gradient-to-br from-indigo-400 to-purple-500 opacity-0 group-hover:opacity-100 rounded-3xl blur-xl transition-all duration-500"></div>
                <div className="relative bg-white border-2 border-indigo-200 hover:border-indigo-400 shadow-xl rounded-3xl transition-all duration-300 h-full flex flex-col">
                  <div className="p-6 sm:p-7 md:p-9 flex flex-col items-center text-center h-full">
                    <div className="relative mb-4">
                      <div className="absolute inset-0 bg-indigo-400 rounded-full blur-lg opacity-30 group-hover:opacity-50 transition-opacity"></div>
                      <div className="relative h-16 w-16 sm:h-20 sm:w-20 bg-gradient-to-br from-indigo-50 to-purple-50 flex items-center justify-center rounded-full border-4 border-indigo-100 shadow-lg">
                        <img src={analysis} alt="Track" className="w-8 h-8 sm:w-12 sm:h-12" />
                      </div>
                    </div>
                    <div className="absolute top-4 left-4 bg-indigo-600 text-white text-xs font-bold px-3 py-1 rounded-full">STEP 2</div>
                    <h3 className="text-2xl sm:text-3xl font-black mb-3 text-gray-900">Track Progress</h3>
                    <p className="text-base text-gray-600 leading-relaxed flex-grow">Monitor the status of your complaints in real-time with live updates.</p>
                    <div className="mt-4 flex items-center text-indigo-600 font-semibold group-hover:translate-x-2 transition-transform">
                      View Tracking <ArrowRight className="w-4 h-4 ml-2" />
                    </div>
                  </div>
                </div>
              </Link>
            </div>

            {/* Stylish Directional Arrow 2 */}
            <div className="flex items-center justify-center px-4 py-2">
              <div className="relative">
                {/* Mobile: Down Arrow */}
                <div className="lg:hidden flex flex-col items-center gap-1 text-purple-400">
                  <div className="w-1 h-8 bg-gradient-to-b from-purple-400 to-pink-400 rounded-full"></div>
                  <ChevronDown className="w-10 h-10 animate-bounce" strokeWidth={3} />
                  <div className="w-1 h-8 bg-gradient-to-b from-pink-400 to-purple-400 rounded-full"></div>
                </div>
                
                {/* Desktop: Right Arrow */}
                <div className="hidden lg:flex items-center gap-1 text-purple-400">
                  <div className="h-1 w-12 bg-gradient-to-r from-purple-400 to-pink-400 rounded-full"></div>
                  <ChevronRight className="w-12 h-12 animate-pulse" strokeWidth={3} />
                  <div className="h-1 w-12 bg-gradient-to-r from-pink-400 to-purple-400 rounded-full"></div>
                </div>
              </div>
            </div>

            {/* STEP 3 */}
            <div className="flex-1 w-full">
              <Link to="/community" className="relative block group h-full">
                <div className="absolute inset-0 bg-gradient-to-br from-purple-400 to-pink-500 opacity-0 group-hover:opacity-100 rounded-3xl blur-xl transition-all duration-500"></div>
                <div className="relative bg-white border-2 border-purple-200 hover:border-purple-400 shadow-xl rounded-3xl transition-all duration-300 h-full flex flex-col">
                  <div className="p-6 sm:p-7 md:p-9 flex flex-col items-center text-center h-full">
                    <div className="relative mb-4">
                      <div className="absolute inset-0 bg-purple-400 rounded-full blur-lg opacity-30 group-hover:opacity-50 transition-opacity"></div>
                      <img src={community} alt="Community" className="relative w-16 h-16 sm:w-20 sm:h-20 rounded-full border-4 border-purple-100 shadow-lg" />
                    </div>
                    <div className="absolute top-4 left-4 bg-purple-600 text-white text-xs font-bold px-3 py-1 rounded-full">STEP 3</div>
                    <h3 className="text-2xl sm:text-3xl font-black mb-3 text-gray-900">Community Impact</h3>
                    <p className="text-base text-gray-600 leading-relaxed flex-grow">See how your reports contribute to city improvement and inspire others.</p>
                    <div className="mt-4 flex items-center text-purple-600 font-semibold group-hover:translate-x-2 transition-transform">
                      Join Community <ArrowRight className="w-4 h-4 ml-2" />
                    </div>
                  </div>
                </div>
              </Link>
            </div>
          </div>
        </section>

        {/* Enhanced Stats Section with Visual Representations */}
       <section className="mt-20 max-w-6xl mx-auto">
  <div className="mb-12 text-center">
    <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-gray-900 mb-3">
      Our{" "}
      <span className="relative inline-block">
        <span className="relative z-10">Impact</span>
        <span className="absolute bottom-0 left-0 w-full h-2 bg-yellow-300"></span>
      </span>
    </h2>
    <p className="text-lg text-gray-600">
      Real numbers, real change in Bangalore
    </p>
  </div>

  <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-8">
    {/* Issues Resolved */}
    <div className="bg-white rounded-3xl p-8 shadow-xl border-2 border-indigo-100 hover:border-indigo-300 transition-all duration-300 hover:shadow-2xl">
      <div className="flex flex-col items-center text-center mb-6">
        <div className="p-3 bg-indigo-100 rounded-2xl mb-3">
          <TrendingUp className="w-8 h-8 text-indigo-600" />
        </div>
        <p className="text-4xl md:text-5xl font-black text-gray-900">10K+</p>
        <p className="text-sm text-gray-500 font-semibold">RESOLVED</p>
      </div>

      <h3 className="text-xl font-bold text-gray-900 mb-4 text-center">
        Issues Resolved
      </h3>

      <div className="space-y-3">
        {[
          ["This Month", "850", "85%"],
          ["Last Month", "720", "72%"],
          ["Avg Monthly", "650", "65%"],
        ].map(([label, value, width]) => (
          <div key={label}>
            <div className="flex justify-between text-xs text-gray-600 mb-1">
              <span>{label}</span>
              <span>{value}</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-3 overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-indigo-500 to-indigo-600 rounded-full"
                style={{ width }}
              />
            </div>
          </div>
        ))}
      </div>

      <div className="mt-4 pt-4 border-t border-gray-200 text-center">
        <p className="text-xs text-green-600 font-bold flex items-center justify-center gap-1">
          <span className="w-2 h-2 bg-green-600 rounded-full animate-pulse" />
          +18% from last month
        </p>
      </div>
    </div>

    {/* Active Citizens */}
    <div className="bg-white rounded-3xl p-8 shadow-xl border-2 border-purple-100 hover:border-purple-300 transition-all duration-300 hover:shadow-2xl">
      <div className="flex flex-col items-center text-center mb-6">
        <div className="p-3 bg-purple-100 rounded-2xl mb-3">
          <Users className="w-8 h-8 text-purple-600" />
        </div>
        <p className="text-4xl md:text-5xl font-black text-gray-900">50K+</p>
        <p className="text-sm text-gray-500 font-semibold">ACTIVE</p>
      </div>

      <h3 className="text-xl font-bold text-gray-900 mb-6 text-center">
        Active Citizens
      </h3>

      <div className="relative w-full aspect-square max-w-[200px] mx-auto">
        <svg className="w-full h-full -rotate-90" viewBox="0 0 100 100">
          <circle cx="50" cy="50" r="40" fill="none" stroke="#f3f4f6" strokeWidth="8" />
          <circle
            cx="50"
            cy="50"
            r="40"
            fill="none"
            stroke="#a855f7"
            strokeWidth="8"
            strokeDasharray="251.2"
            strokeDashoffset="62.8"
            strokeLinecap="round"
          />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <p className="text-3xl font-black text-purple-600">75%</p>
          <p className="text-xs text-gray-500">Engagement</p>
        </div>
      </div>

      <div className="mt-4 pt-4 border-t border-gray-200 text-center">
        <p className="text-xs text-purple-600 font-bold flex items-center justify-center gap-1">
          <span className="w-2 h-2 bg-purple-600 rounded-full animate-pulse" />
          High community engagement
        </p>
      </div>
    </div>

    {/* System Monitoring */}
    <div className="bg-white rounded-3xl p-8 shadow-xl border-2 border-pink-100 hover:border-pink-300 transition-all duration-300 hover:shadow-2xl">
      <div className="flex flex-col items-center text-center mb-6">
        <div className="p-3 bg-pink-100 rounded-2xl mb-3">
          <Shield className="w-8 h-8 text-pink-600" />
        </div>
        <p className="text-4xl md:text-5xl font-black text-gray-900">24/7</p>
        <p className="text-sm text-gray-500 font-semibold">UPTIME</p>
      </div>

      <h3 className="text-xl font-bold text-gray-900 mb-6 text-center">
        System Monitoring
      </h3>

      <div className="space-y-4">
        {[
          ["Server Status", "ONLINE"],
          ["Database", "ACTIVE"],
          ["Response Time", "45ms"],
        ].map(([label, value]) => (
          <div
            key={label}
            className="flex justify-between items-center p-3 rounded-xl border bg-green-50 border-green-200"
          >
            <span className="text-sm font-semibold text-gray-700">{label}</span>
            <span className="text-xs font-bold text-green-600">{value}</span>
          </div>
        ))}
      </div>

      <div className="mt-4 pt-4 border-t border-gray-200 text-center">
        <p className="text-xs text-green-600 font-bold flex items-center justify-center gap-1">
          <span className="w-2 h-2 bg-green-600 rounded-full animate-pulse" />
          99.9% uptime this month
        </p>
      </div>
    </div>

    {/* Resolution Velocity */}
    <div className="bg-white rounded-3xl p-8 shadow-xl border-2 border-emerald-100 hover:border-emerald-300 transition-all duration-300 hover:shadow-2xl">
      <div className="flex flex-col items-center text-center mb-6">
        <div className="p-3 bg-emerald-100 rounded-2xl mb-3">
          <Clock className="w-8 h-8 text-emerald-600" />
        </div>
        <p className="text-4xl md:text-5xl font-black text-gray-900">3.2</p>
        <p className="text-sm text-gray-500 font-semibold">DAYS AVG</p>
      </div>

      <h3 className="text-xl font-bold text-gray-900 mb-4 text-center">
        Resolution Velocity
      </h3>

      <div className="space-y-3">
        {[
          ["Current Avg", "3.2 days", "80%"],
          ["Previous Avg", "4.7 days", "55%"],
        ].map(([label, value, width]) => (
          <div key={label}>
            <div className="flex justify-between text-xs text-gray-600 mb-1">
              <span>{label}</span>
              <span>{value}</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-3 overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-emerald-500 to-emerald-600 rounded-full"
                style={{ width }}
              />
            </div>
          </div>
        ))}
      </div>

      <div className="mt-4 pt-4 border-t border-gray-200 text-center">
        <p className="text-xs text-emerald-600 font-bold flex items-center justify-center gap-1">
          <span className="w-2 h-2 bg-emerald-600 rounded-full animate-pulse" />
          32% faster resolution time
        </p>
      </div>
    </div>

   
  </div>
</section>


        {/* Features Highlight */}
       <section className="mt-16 max-w-5xl mx-auto">
  <div className="bg-white rounded-3xl p-8 md:p-12 shadow-xl shadow-indigo-100/50 border border-indigo-100 relative overflow-hidden">
    
    {/* Subtle background blurs for a soft highlight effect */}
    <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-50/50 rounded-full -translate-y-1/2 translate-x-1/2 blur-3xl"></div>
    <div className="absolute bottom-0 left-0 w-48 h-48 bg-purple-50/50 rounded-full translate-y-1/2 -translate-x-1/2 blur-2xl"></div>

    <div className="relative z-10">
      <div className="flex items-center justify-center mb-4">
        <div className="p-3 bg-indigo-50 rounded-full border border-indigo-100">
          <Zap className="w-8 h-8 text-indigo-600" />
        </div>
      </div>
      
      <h2 className="text-3xl md:text-4xl font-black text-center mb-12 text-gray-900">
        Why Choose NagrikMitra?
      </h2>

      <div className="grid md:grid-cols-3 gap-8 relative">
        {/* Feature 1: Transparent (Blue Theme) */}
        <div className="flex flex-col items-center text-center group">
          <div className="mb-4 p-4 rounded-2xl bg-blue-50 text-blue-600 group-hover:bg-blue-100 group-hover:scale-110 transition-all duration-300 border border-blue-100">
            <CheckCircle className="w-8 h-8" />
          </div>
          <h3 className="font-bold text-xl mb-2 text-gray-900">100% Transparent</h3>
          <p className="text-gray-600 text-sm leading-relaxed max-w-xs">
            Track every step of your complaint resolution process in real-time.
          </p>
        </div>

        {/* Feature 2: Secure (Purple Theme) */}
        <div className="flex flex-col items-center text-center group">
          <div className="mb-4 p-4 rounded-2xl bg-purple-50 text-purple-600 group-hover:bg-purple-100 group-hover:scale-110 transition-all duration-300 border border-purple-100">
            <Shield className="w-8 h-8" />
          </div>
          <h3 className="font-bold text-xl mb-2 text-gray-900">Secure & Safe</h3>
          <p className="text-gray-600 text-sm leading-relaxed max-w-xs">
            Government-backed platform ensuring your data remains protected.
          </p>
        </div>

        {/* Feature 3: Proven (Indigo Theme) */}
        <div className="flex flex-col items-center text-center group">
          <div className="mb-4 p-4 rounded-2xl bg-indigo-50 text-indigo-600 group-hover:bg-indigo-100 group-hover:scale-110 transition-all duration-300 border border-indigo-100">
            <TrendingUp className="w-8 h-8" />
          </div>
          <h3 className="font-bold text-xl mb-2 text-gray-900">Proven Results</h3>
          <p className="text-gray-600 text-sm leading-relaxed max-w-xs">
            Thousands of civic issues resolved successfully across the city.
          </p>
        </div>
      </div>
    </div>
  </div>
</section>
      </main>

      <section className="w-full bg-gradient-to-b from-white via-slate-50 to-blue-50 py-16 sm:py-20 lg:py-24 px-4 sm:px-6 md:px-8 lg:px-12">
      </section>

      <Footer />

      <style jsx>{`
        @keyframes blob {
          0% { transform: translate(0px, 0px) scale(1); }
          33% { transform: translate(30px, -50px) scale(1.1); }
          66% { transform: translate(-20px, 20px) scale(0.9); }
          100% { transform: translate(0px, 0px) scale(1); }
        }
        .animate-blob {
          animation: blob 7s infinite;
        }
        .animation-delay-2000 {
          animation-delay: 2s;
        }
        .animation-delay-4000 {
          animation-delay: 4s;
        }
      `}</style>
    </div>
  );
};

export default Landing;