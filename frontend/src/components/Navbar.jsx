import { useState } from "react";
import { useAuth } from "../AuthProvider";
import { Link } from "react-router-dom";
import logo_1 from "../assets/logo-1.png";
import logo_2 from "../assets/logo-2.png";
import { Menu, X } from "lucide-react";

const Navbar = () => {
  const { loginWithEmail, loginWithGoogle, register, logout, isAuthenticated, isLoading } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);

  const handleLogin = () => {
    window.location.href = '/login';
  };
  const handleRegister = async () => await register();
  const handleLogout = async () => await logout();

  if (isLoading) {
    return (
      <header className="bg-white border-b-2 border-blue-100 shadow-md w-full fixed top-0 left-0 z-50">
        <div className="max-w-screen-xl mx-auto flex justify-between items-center px-4 py-4">
          <div className="text-xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">NagrikMitra</div>
          <div className="text-gray-600">Loading...</div>
        </div>
      </header>
    );
  }

  return (
    <header className="bg-white/95 backdrop-blur-md border-b-2 border-blue-100 shadow-lg w-full fixed top-0 left-0 z-50">
      <div className="max-w-screen-xl mx-auto flex justify-between items-center px-4 py-2">
        <Link
          to="/"
          className="flex items-center gap-2 font-bold py-1 hover:opacity-80 transition"
        >
          <img src={logo_1} alt="logo" className="w-12 h-12 sm:w-16 sm:h-16" />
          <img src={logo_2} alt="logo" className="h-8 sm:h-12" />
        </Link>

        <nav className="hidden md:flex items-center font-semibold text-lg lg:text-xl gap-6">
          {isAuthenticated ? (
            <>
              <Link to="/report" className="text-gray-700 hover:text-blue-600 transition-colors duration-200 hover:underline decoration-2 decoration-blue-600 underline-offset-4">
                Report
              </Link>
              <Link to="/track" className="text-gray-700 hover:text-blue-600 transition-colors duration-200 hover:underline decoration-2 decoration-blue-600 underline-offset-4">
                Track
              </Link>
              <Link to="/history" className="text-gray-700 hover:text-blue-600 transition-colors duration-200 hover:underline decoration-2 decoration-blue-600 underline-offset-4">
                History
              </Link>
              <Link to="/profile" className="text-gray-700 hover:text-blue-600 transition-colors duration-200 hover:underline decoration-2 decoration-blue-600 underline-offset-4">
                Profile
              </Link>
              <Link to="/community" className="text-gray-700 hover:text-blue-600 transition-colors duration-200 hover:underline decoration-2 decoration-blue-600 underline-offset-4">
                Community
              </Link>
              <button
                onClick={handleLogout}
                className="bg-gradient-to-r from-red-500 to-red-600 text-white px-4 py-2 rounded-lg hover:from-red-600 hover:to-red-700 transition-all duration-200 shadow-md hover:shadow-lg"
              >
                Logout
              </button>
            </>
          ) : (
            <>
              <button
                onClick={handleLogin}
                className="text-gray-700 hover:text-blue-600 transition-colors duration-200 hover:underline decoration-2 decoration-blue-600 underline-offset-4"
              >
                Login
              </button>
              <button
                onClick={handleRegister}
                className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-5 py-2 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all duration-200 shadow-md hover:shadow-lg"
              >
                Sign Up
              </button>
            </>
          )}
        </nav>

        <button
          className="md:hidden flex items-center justify-center w-10 h-10 rounded-md hover:bg-blue-50 transition text-gray-700"
          onClick={() => setMenuOpen(!menuOpen)}
          aria-label="Toggle menu"
        >
          {menuOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>

      <div
        className={`md:hidden bg-white border-t border-blue-100 text-gray-700 font-semibold text-base flex flex-col items-center gap-4 overflow-hidden transition-all duration-300 ${
          menuOpen ? "max-h-96 py-4" : "max-h-0 py-0"
        }`}
      >
        {isAuthenticated ? (
          <>
            <Link
              to="/report"
              onClick={() => setMenuOpen(false)}
              className="hover:text-blue-600 transition-colors"
            >
              Report
            </Link>
            <Link
              to="/track"
              onClick={() => setMenuOpen(false)}
              className="hover:text-blue-600 transition-colors"
            >
              Track
            </Link>
            <Link
              to="/history"
              onClick={() => setMenuOpen(false)}
              className="hover:text-blue-600 transition-colors"
            >
              History
            </Link>
            <Link
              to="/profile"
              onClick={() => setMenuOpen(false)}
              className="hover:text-blue-600 transition-colors"
            >
              Profile
            </Link>
            <Link
              to="/community"
              onClick={() => setMenuOpen(false)}
              className="hover:text-blue-600 transition-colors"
            >
              Community
            </Link>
            <button
              onClick={() => {
                handleLogout();
                setMenuOpen(false);
              }}
              className="bg-gradient-to-r from-red-500 to-red-600 text-white px-6 py-2 rounded-lg hover:from-red-600 hover:to-red-700 transition-all duration-200 shadow-md"
            >
              Logout
            </button>
          </>
        ) : (
          <>
            <button
              onClick={() => {
                handleLogin();
                setMenuOpen(false);
              }}
              className="hover:text-blue-600 transition-colors"
            >
              Login
            </button>
            <button
              onClick={() => {
                handleRegister();
                setMenuOpen(false);
              }}
              className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-6 py-2 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all duration-200 shadow-md"
            >
              Sign Up
            </button>
          </>
        )}
      </div>
    </header>
  );
};

export default Navbar;