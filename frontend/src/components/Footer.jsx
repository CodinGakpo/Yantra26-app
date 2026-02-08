import logo from "../assets/logo-1.png";
import { MapPin, Mail, Heart, BookOpen } from "lucide-react";

const Footer = () => {
  return (
    <footer className="bg-gradient-to-b from-slate-50 to-blue-100 text-gray-800 border-t-2 border-blue-200">
      <div className="container mx-auto px-6 md:px-20 py-12 md:py-16">
        <div className="grid md:grid-cols-3 gap-12 text-center md:text-left">
          <div>
            <div className="flex items-center justify-center md:justify-start mb-4">
              <img 
                src={logo} 
                alt="NagrikMitra Logo" 
                className="w-12 h-12 mr-3 object-contain"
              />
              <h2 className="text-2xl font-bold text-black bg-gradient-to-r bg-clip-text">NagrikMitra</h2>
            </div>
            <p className="text-gray-600 leading-relaxed">
              Empowering citizens to make Bangalore cleaner, safer, and smarter – one report at a time.
            </p>
            <p className="text-xsmt-4 uppercase tracking-wider font-bold">
              CIVIC | CONNECT | RESOLVE
            </p>
          </div>

          <div>
            <h3 className="text-lg font-bold mb-4 text-gray-800 border-b-2 border-blue-300 inline-block pb-1">Quick Links</h3>
            <ul className="space-y-2.5 text-gray-600">
              <li>
                <a href="/" className="hover:text-blue-600 transition-colors duration-200 inline-block font-medium">
                  Home
                </a>
              </li>
              <li>
                <a href="/report" className="hover:text-blue-600 transition-colors duration-200 inline-block font-medium">
                  Report Issue
                </a>
              </li>
              <li>
                <a href="/track" className="hover:text-blue-600 transition-colors duration-200 inline-block font-medium">
                  Track Complaints
                </a>
              </li>
              <li>
                <a href="/community" className="hover:text-blue-600 transition-colors duration-200 inline-block font-medium">
                  Community Page
                </a>
              </li>
              <li>
                <a href="/profile" className="hover:text-blue-600 transition-colors duration-200 inline-block font-medium">
                  Profile
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="text-lg font-bold mb-4 text-gray-800 border-b-2 border-blue-300 inline-block pb-1">Get in Touch</h3>
            <div className="space-y-3 text-gray-600">
              <p className="flex items-center justify-center md:justify-start">
                <MapPin className="w-4 h-4 mr-2 text-blue-600" />
                <span className="font-medium">Bangalore, India</span>
              </p>
              <p className="flex items-center justify-center md:justify-start">
                <Mail className="w-4 h-4 mr-2 text-blue-600" />
                <a href="mailto:support@nagrikmitra.in" className="hover:text-blue-600 transition-colors duration-200 font-medium">
                  support@nagrikmitra.in
                </a>
              </p>
              <p className="flex items-center justify-center md:justify-start text-sm pt-2">
                <span className="text-gray-500 bg-blue-50 px-3 py-1 rounded-full text-xs font-semibold">🔒 Secure government portal</span>
              </p>
            </div>
          </div>
        </div>

        <div className="border-t-2 border-blue-200 mt-12 pt-6">
          <div className="text-center space-y-2">
            <p className="text-gray-600 text-sm font-medium">
              © {new Date().getFullYear()} NagrikMitra · Government of India · Ministry of Urban Development
            </p>
            <p className="text-gray-500 text-xs">
              All rights reserved · All activities are monitored
            </p>
            <p className="text-gray-600 text-xs pt-3 border-t border-blue-100 mt-4 inline-flex items-center gap-1.5 px-4">
              <span>Built with</span>
              <Heart className="w-3 h-3 text-red-500 fill-red-500" />
              <span>by BTech students at VIT Vellore</span>
            </p>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;