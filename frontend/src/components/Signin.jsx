import { useAuth } from "../AuthProvider";
import { useState, useEffect } from "react";
import { Mail, Lock, User, Home, Sparkles } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { GoogleLogin } from "@react-oauth/google";
import logo from "../assets/logo-1.png";

const Signin = () => {
  const { loginWithGoogle, register, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    confirmPassword: "",
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (isAuthenticated) {
      navigate("/");
    }
  }, [isAuthenticated, navigate]);

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
    setError("");
  };

  const handleEmailSignup = async (e) => {
    e.preventDefault();

    if (formData.password !== formData.confirmPassword) {
      setError("Passwords do not match");
      return;
    }

    if (formData.password.length < 8) {
      setError("Password must be at least 8 characters");
      return;
    }

    setIsLoading(true);
    setError("");
    try {
      await register(formData.email, formData.password);
      navigate("/profile");
    } catch (error) {
      setError(error.message || "Registration failed");
      console.error("Registration error:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleSignup = async (credentialResponse) => {
    setIsLoading(true);
    setError("");
    try {
      await loginWithGoogle(credentialResponse);
      navigate("/profile");
    } catch (error) {
      setError(error.message || "Google sign up failed");
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleError = () => {
    setError("Google signup was cancelled or failed");
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
                Create Account
              </h2>
            </div>

            <div className="px-4 py-6 sm:px-6 sm:py-8 space-y-5">
              <div className="flex justify-center">
                <GoogleLogin
                  onSuccess={handleGoogleSignup}
                  onError={handleGoogleError}
                  useOneTap={false}
                  theme="outline"
                  size="large"
                  text="signup_with"
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
                    Or sign up with email
                  </span>
                </div>
              </div>

              {error && (
                <div className="bg-red-50 border-2 border-red-200 text-red-700 px-3 py-2.5 sm:px-4 sm:py-3 rounded-xl text-xs sm:text-sm font-medium">
                  {error}
                </div>
              )}

              <form onSubmit={handleEmailSignup} className="space-y-4">
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
                      name="email"
                      value={formData.email}
                      onChange={handleChange}
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
                      name="password"
                      value={formData.password}
                      onChange={handleChange}
                      className="w-full pl-10 sm:pl-12 pr-3 sm:pr-4 py-2.5 sm:py-3.5 text-sm sm:text-base bg-white border-2 border-gray-200 text-gray-900 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 placeholder-gray-400 transition-all"
                      placeholder="••••••••"
                      required
                      disabled={isLoading}
                      minLength={8}
                    />
                  </div>
                  <p className="text-xs text-gray-500 mt-1">Must be at least 8 characters</p>
                </div>

                <div className="space-y-2">
                  <label className="block text-xs sm:text-sm font-bold text-gray-700">
                    Confirm Password
                  </label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 sm:pl-4 flex items-center pointer-events-none">
                      <Lock className="h-4 w-4 sm:h-5 sm:w-5 text-indigo-400" />
                    </div>
                    <input
                      type="password"
                      name="confirmPassword"
                      value={formData.confirmPassword}
                      onChange={handleChange}
                      className="w-full pl-10 sm:pl-12 pr-3 sm:pr-4 py-2.5 sm:py-3.5 text-sm sm:text-base bg-white border-2 border-gray-200 text-gray-900 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 placeholder-gray-400 transition-all"
                      placeholder="••••••••"
                      required
                      disabled={isLoading}
                      minLength={8}
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full bg-black text-white py-2.5 sm:py-3.5 rounded-xl text-sm sm:text-base font-bold hover:from-indigo-700 hover:to-purple-700 transition-all duration-300 flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl mt-4 sm:mt-6"
                >
                  <Mail className="w-4 h-4 sm:w-5 sm:h-5" />
                  {isLoading ? "Creating Account..." : "Create Account"}
                </button>
              </form>

              <div className="text-center text-xs sm:text-sm text-gray-600 pt-2">
                Already have an account?{" "}
                <a
                  href="/login"
                  className="text-indigo-600 hover:text-indigo-700 font-bold transition-colors hover:underline"
                >
                  Sign In
                </a>
              </div>
            </div>
          </div>

          <div className="mt-6 text-center space-y-2">
            <p className="text-xs text-gray-600 font-medium">
              By signing up, you agree to our Terms of Service and Privacy
              Policy
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

export default Signin;