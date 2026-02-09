import { useAuth } from "../AuthProvider";
import { useState, useEffect } from "react";
import { Mail, Lock, User, ArrowRight, Check, Home, Sparkles } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { GoogleLogin } from "@react-oauth/google";
import { getApiUrl } from "../utils/api";
import logo from "../assets/logo-1.png";

const Login = () => {
  const { loginWithEmail, loginWithGoogle, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const [loginMethod, setLoginMethod] = useState("password");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [otpEmail, setOtpEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [otpSent, setOtpSent] = useState(false);
  const [otpTimer, setOtpTimer] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (isAuthenticated) {
      navigate("/");
    }
  }, [isAuthenticated, navigate]);

  useEffect(() => {
    if (otpTimer > 0) {
      const timer = setTimeout(() => setOtpTimer(otpTimer - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [otpTimer]);

  const handlePasswordLogin = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError("");
    try {
      await loginWithEmail(email, password);
      navigate("/");
    } catch (error) {
      setError(error.message || "Login failed. Please check your credentials.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleRequestOTP = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError("");

    try {
      const response = await fetch(getApiUrl("/users/request-otp/"), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email: otpEmail }),
      });

      const data = await response.json();

      if (response.ok) {
        setOtpSent(true);
        setOtpTimer(600);
        setError("");
      } else {
        setError(data.email?.[0] || data.error || "Failed to send code");
      }
    } catch (error) {
      setError("Network error. Please try again.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerifyOTP = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError("");

    try {
      const response = await fetch(getApiUrl("/users/verify-otp/"), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email: otpEmail, otp }),
      });

      const data = await response.json();

      if (response.ok) {
        localStorage.setItem("accessToken", data.tokens.access);
        localStorage.setItem("refreshToken", data.tokens.refresh);
        window.location.href = "/";
      } else {
        setError(
          data.otp?.[0] || data.email?.[0] || data.error || "Invalid code"
        );
      }
    } catch (error) {
      setError("Network error. Please try again.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleLogin = async (credentialResponse) => {
    setIsLoading(true);
    setError("");
    try {
      await loginWithGoogle(credentialResponse);
      navigate("/");
    } catch (error) {
      setError(error.message || "Google login failed");
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleError = () => {
    setError("Google login was cancelled or failed");
  };

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, "0")}`;
  };

  return (
    <>
      <style>
        {`
          @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
          }
          @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-20px); }
          }
          .fade-in {
            animation: fadeIn 0.6s ease-out forwards;
          }
          .float-animation {
            animation: float 6s ease-in-out infinite;
          }
        `}
      </style>

      <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 flex items-center justify-center px-4 py-6 relative overflow-hidden">
        {/* Decorative background blobs */}
        <div className="fixed top-20 right-10 w-72 h-72 bg-blue-300 rounded-full mix-blend-multiply filter blur-3xl opacity-30 float-animation"></div>
        <div className="fixed top-40 left-10 w-72 h-72 bg-purple-300 rounded-full mix-blend-multiply filter blur-3xl opacity-30 float-animation" style={{animationDelay: "2s"}}></div>
        <div className="fixed bottom-20 left-1/2 w-72 h-72 bg-indigo-300 rounded-full mix-blend-multiply filter blur-3xl opacity-30 float-animation" style={{animationDelay: "4s"}}></div>

        <button
          onClick={() => navigate("/")}
          className="absolute top-4 left-4 sm:top-6 sm:left-6 flex items-center gap-2 text-gray-600 hover:text-indigo-600 transition-colors group z-20 bg-white/80 backdrop-blur-sm px-4 py-2 rounded-full shadow-md hover:shadow-lg"
        >
          <Home className="w-5 h-5" />
          <span className="text-sm font-semibold">Home</span>
        </button>

        <div className="relative z-10 w-full max-w-md fade-in">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center mb-4 relative">
              <div className="absolute inset-0 bg-gradient-to-r from-blue-400 to-purple-400 rounded-full blur-2xl opacity-30"></div>
              <img src={logo} alt="NagrikMitra Logo" className="w-20 h-20 sm:w-24 sm:h-24 object-contain relative z-10" />
            </div>
            <h1 className="text-3xl sm:text-4xl font-black text-gray-900 mb-2 tracking-tight">
              NagrikMitra
            </h1>
            <p className="text-xs sm:text-sm text-indigo-600 font-bold uppercase tracking-wider flex items-center justify-center gap-2">
              <Sparkles className="w-4 h-4" />
              CIVIC | CONNECT | RESOLVE
            </p>
          </div>

          <div className="bg-white/90 backdrop-blur-xl rounded-3xl overflow-hidden shadow-2xl border-2 border-indigo-100">
            <div className="bg-black px-6 py-4 sm:py-5">
              <h2 className="text-white text-lg sm:text-xl font-black text-center">
                Secure Login
              </h2>
            </div>

            <div className="px-4 py-6 sm:px-6 sm:py-8 space-y-5">
              <div className="flex justify-center">
                <GoogleLogin
                  onSuccess={handleGoogleLogin}
                  onError={handleGoogleError}
                  useOneTap={false}
                  theme="outline"
                  size="large"
                  text="continue_with"
                  shape="pill"
                  logo_alignment="left"
                />
              </div>

              <div className="relative">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t-2 border-gray-200"></div>
                </div>
                <div className="relative flex justify-center text-sm">
                  <span className="px-4 bg-white text-gray-500 font-semibold">
                    Or continue with
                  </span>
                </div>
              </div>

              <div className="flex gap-2 bg-gray-100 p-1.5 rounded-xl">
                <button
                  onClick={() => setLoginMethod("password")}
                  className={`flex-1 px-3 py-2.5 rounded-lg text-xs sm:text-sm font-bold transition-all duration-200 ${
                    loginMethod === "password"
                      ? "bg-white text-indigo-600 shadow-md"
                      : "text-gray-600 hover:text-gray-900"
                  }`}
                >
                  Password
                </button>
                <button
                  onClick={() => setLoginMethod("otp")}
                  className={`flex-1 px-3 py-2.5 rounded-lg text-xs sm:text-sm font-bold transition-all duration-200 ${
                    loginMethod === "otp"
                      ? "bg-white text-indigo-600 shadow-md"
                      : "text-gray-600 hover:text-gray-900"
                  }`}
                >
                  Email Code
                </button>
              </div>

              {error && (
                <div className="bg-red-50 border-2 border-red-200 text-red-700 px-3 py-2.5 sm:px-4 sm:py-3 rounded-xl text-xs sm:text-sm font-medium">
                  {error}
                </div>
              )}

              {loginMethod === "password" && (
                <form onSubmit={handlePasswordLogin} className="space-y-4">
                  <div className="space-y-2">
                    <label className="block text-xs sm:text-sm font-bold text-gray-700">
                      Email Address
                    </label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 sm:pl-4 flex items-center pointer-events-none">
                        <User className="h-4 w-4 sm:h-5 sm:w-5 text-indigo-400" />
                      </div>
                      <input
                        type="email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        className="w-full pl-10 sm:pl-12 pr-3 sm:pr-4 py-2.5 sm:py-3.5 text-sm sm:text-base bg-white border-2 border-gray-200 text-gray-900 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 placeholder-gray-400 transition-all"
                        placeholder="your.email@example.com"
                        required
                        disabled={isLoading}
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <label className="block text-xs sm:text-sm font-bold text-gray-700">
                      Password
                    </label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 sm:pl-4 flex items-center pointer-events-none">
                        <Lock className="h-4 w-4 sm:h-5 sm:w-5 text-indigo-400" />
                      </div>
                      <input
                        type="password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        className="w-full pl-10 sm:pl-12 pr-3 sm:pr-4 py-2.5 sm:py-3.5 text-sm sm:text-base bg-white border-2 border-gray-200 text-gray-900 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 placeholder-gray-400 transition-all"
                        placeholder="••••••••"
                        required
                        disabled={isLoading}
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    disabled={isLoading}
                    className="w-full bg-black text-white py-2.5 sm:py-3.5 rounded-xl text-sm sm:text-base font-bold hover:from-indigo-700 hover:to-purple-700 transition-all duration-300 flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl mt-4 sm:mt-6"
                  >
                    {isLoading ? (
                      "Signing in..."
                    ) : (
                      <>
                        <Mail className="w-4 h-4 sm:w-5 sm:h-5" />
                        Sign In with Password
                      </>
                    )}
                  </button>
                </form>
              )}

              {loginMethod === "otp" && !otpSent && (
                <form onSubmit={handleRequestOTP} className="space-y-4">
                  <div className="space-y-2">
                    <label className="block text-xs sm:text-sm font-bold text-gray-700">
                      Email Address
                    </label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 sm:pl-4 flex items-center pointer-events-none">
                        <User className="h-4 w-4 sm:h-5 sm:w-5 text-indigo-400" />
                      </div>
                      <input
                        type="email"
                        value={otpEmail}
                        onChange={(e) => setOtpEmail(e.target.value)}
                        className="w-full pl-10 sm:pl-12 pr-3 sm:pr-4 py-2.5 sm:py-3.5 text-sm sm:text-base bg-white border-2 border-gray-200 text-gray-900 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 placeholder-gray-400 transition-all"
                        placeholder="your.email@example.com"
                        required
                        disabled={isLoading}
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    disabled={isLoading}
                    className="w-full bg-black text-white py-2.5 sm:py-3.5 rounded-xl text-sm sm:text-base font-bold hover:from-indigo-700 hover:to-purple-700 transition-all duration-300 flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl"
                  >
                    {isLoading ? (
                      "Sending code..."
                    ) : (
                      <>
                        <ArrowRight className="w-4 h-4 sm:w-5 sm:h-5" />
                        Send Login Code
                      </>
                    )}
                  </button>
                </form>
              )}

              {loginMethod === "otp" && otpSent && (
                <form onSubmit={handleVerifyOTP} className="space-y-4">
                  <div className="bg-green-50 border-2 border-green-200 text-green-700 px-3 py-2.5 sm:px-4 sm:py-3 rounded-xl text-xs sm:text-sm flex items-start gap-2">
                    <Check className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0 mt-0.5" />
                    <div>
                      <p className="font-bold">Code sent to {otpEmail}</p>
                      <p className="text-xs mt-1">
                        Check your email for the 6-digit code
                      </p>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <label className="block text-xs sm:text-sm font-bold text-gray-700">
                      Enter 6-Digit Code
                    </label>
                    <input
                      type="text"
                      value={otp}
                      onChange={(e) =>
                        setOtp(e.target.value.replace(/\D/g, "").slice(0, 6))
                      }
                      className="w-full px-3 sm:px-4 py-2.5 sm:py-3.5 bg-white border-2 border-gray-200 text-gray-900 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 placeholder-gray-400 transition-all text-center text-xl sm:text-2xl tracking-widest font-mono font-bold"
                      placeholder="000000"
                      required
                      disabled={isLoading}
                      maxLength={6}
                    />
                  </div>

                  {otpTimer > 0 && (
                    <p className="text-xs sm:text-sm text-gray-600 text-center">
                      Code expires in{" "}
                      <span className="font-mono font-bold text-indigo-600">
                        {formatTime(otpTimer)}
                      </span>
                    </p>
                  )}

                  <button
                    type="submit"
                    disabled={isLoading || otp.length !== 6}
                    className="w-full bg-gradient-to-r from-indigo-600 to-purple-600 text-white py-2.5 sm:py-3.5 rounded-xl text-sm sm:text-base font-bold hover:from-indigo-700 hover:to-purple-700 transition-all duration-300 flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl"
                  >
                    {isLoading ? "Verifying..." : "Verify & Sign In"}
                  </button>

                  <button
                    type="button"
                    onClick={() => {
                      setOtpSent(false);
                      setOtp("");
                      setError("");
                    }}
                    className="w-full text-gray-600 hover:text-indigo-600 text-xs sm:text-sm font-semibold transition-colors"
                  >
                    Use a different email
                  </button>
                </form>
              )}

              <div className="text-center text-xs sm:text-sm text-gray-600 pt-2">
                Don't have an account?{" "}
                <a
                  href="/register"
                  className="text-indigo-600 hover:text-indigo-700 font-bold transition-colors hover:underline"
                >
                  Sign Up
                </a>
              </div>
            </div>
          </div>

          <div className="mt-6 text-center space-y-2">
            <p className="text-xs text-gray-600 font-medium">
              🔒 Secure government portal • All activities are monitored
            </p>
            <p className="text-xs text-gray-500">
              © 2026 NagrikMitra • Government of India
            </p>
          </div>
        </div>
      </div>
    </>
  );
};

export default Login;