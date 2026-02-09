import { useState, useEffect } from "react";
import Navbar from "./MiniNavbar";
import folder from "../assets/foldericon.png";
import { useAuth } from "../AuthProvider";
import Footer from "./Footer";
import { classifyImage } from "../ai/classifyImage";
import {
  User,
  FileText,
  Image as ImageIcon,
  MapPin,
  AlertCircle,
  CheckCircle,
  Calendar,
  Mail,
  Phone,
  X,
  Copy,
  ArrowRight,
} from "lucide-react";
import "leaflet/dist/leaflet.css";
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import L from "leaflet";
import { getApiUrl } from "../utils/api";
import EXIF from "exif-js";

function Report() {
  const [preview, setPreview] = useState(null);
  const [selectedFile, setSelectedFile] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [userProfile, setUserProfile] = useState(null);
  const [showSuccessPopup, setShowSuccessPopup] = useState(false);
  const [showUnverifiedPopup, setShowUnverifiedPopup] = useState(false);
  const [applicationId, setApplicationId] = useState(null);
  const { user, getAuthHeaders } = useAuth();
  const [showMap, setShowMap] = useState(false);
  const [tempLocation, setTempLocation] = useState(null);
  const [tempPosition, setTempPosition] = useState(null);
  const [isExtractingLocation, setIsExtractingLocation] = useState(false);
  const [geotagWarning, setGeotagWarning] = useState("");
  const [copiedId, setCopiedId] = useState(false);

  const [formData, setFormData] = useState({
    issue_title: "",
    location: "",
    issue_description: "",
    image_url: "",
  });
  const [errors, setErrors] = useState({
    issue_title: "",
    issue_description: "",
    image: "",
  });

  useEffect(() => {
    const fetchUserProfile = async () => {
      try {
        const headers = await getAuthHeaders();
        const response = await fetch(getApiUrl("/profile/me/"), {
          headers,
        });
        if (response.ok) {
          const data = await response.json();
          setUserProfile(data);

          if (!data.is_aadhaar_verified) {
            setShowUnverifiedPopup(true);
          }
        } else {
          console.error("Failed to fetch profile:", response.status);
        }
      } catch (error) {
        console.error("Error fetching profile:", error);
      }
    };
    if (user) fetchUserProfile();
  }, [user, getAuthHeaders]);

  // Convert GPS coordinates from EXIF format to decimal
  const convertDMSToDD = (degrees, minutes, seconds, direction) => {
    let dd = degrees + minutes / 60 + seconds / 3600;
    if (direction === "S" || direction === "W") {
      dd = dd * -1;
    }
    return dd;
  };

  // Extract geolocation from image EXIF data
  const extractGeolocation = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      
      reader.onload = function (e) {
        const image = new Image();
        image.src = e.target.result;
        
        image.onload = function () {
          EXIF.getData(image, function () {
            const allTags = EXIF.getAllTags(this);
            console.log("All EXIF tags:", allTags);
            
            const lat = EXIF.getTag(this, "GPSLatitude");
            const latRef = EXIF.getTag(this, "GPSLatitudeRef");
            const lon = EXIF.getTag(this, "GPSLongitude");
            const lonRef = EXIF.getTag(this, "GPSLongitudeRef");

            console.log("GPS Data:", { lat, latRef, lon, lonRef });

            if (lat && lon && latRef && lonRef) {
              const latitude = convertDMSToDD(lat[0], lat[1], lat[2], latRef);
              const longitude = convertDMSToDD(lon[0], lon[1], lon[2], lonRef);
              
              console.log("Converted coordinates:", { latitude, longitude });
              resolve({ latitude, longitude });
            } else {
              reject(new Error("No GPS data found in image"));
            }
          });
        };
        
        image.onerror = function () {
          reject(new Error("Failed to load image"));
        };
      };
      
      reader.onerror = function () {
        reject(new Error("Failed to read file"));
      };
      
      reader.readAsDataURL(file);
    });
  };

  // Reverse geocode using Nominatim (OpenStreetMap)
  const reverseGeocode = async (latitude, longitude) => {
    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&accept-language=en`,
        {
          headers: {
            "User-Agent": "ReportMitra/1.0 (contact@reportmitra.in)",
          },
        }
      );

      if (!response.ok) {
        throw new Error("Reverse geocoding failed");
      }

      const data = await response.json();
      return data.display_name || `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
    } catch (error) {
      console.error("Reverse geocoding error:", error);
      return `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
    }
  };

  const handleFileChange = async (e) => {
    const file = e.target.files && e.target.files[0];
    if (file) {
      setSelectedFile(file);
      setPreview(URL.createObjectURL(file));
      setFormData((p) => ({ ...p, image_url: "" }));
      setErrors((p) => ({ ...p, image: "" }));
      setGeotagWarning("");

      // Extract geolocation from image
      setIsExtractingLocation(true);
      try {
        const { latitude, longitude } = await extractGeolocation(file);
        
        console.log("Successfully extracted GPS:", { latitude, longitude });
        
        // Get human-readable address
        const address = await reverseGeocode(latitude, longitude);
        
        console.log("Geocoded address:", address);
        
        // Update form data and map position
        setFormData((p) => ({ ...p, location: address }));
        setTempPosition([latitude, longitude]);
        setTempLocation(address);
        
        setGeotagWarning("");
      } catch (error) {
        console.error("Geolocation extraction error:", error);
        setGeotagWarning("⚠️ No GPS data found in image. Please use the map to select location.");
        setFormData((p) => ({ ...p, location: "" }));
      } finally {
        setIsExtractingLocation(false);
      }
    } else {
      if (preview) {
        URL.revokeObjectURL(preview);
      }
      setSelectedFile(null);
      setPreview(null);
      setFormData((p) => ({ ...p, image_url: "", location: "" }));
      setGeotagWarning("");
    }
  };

  const uploadFileToS3 = async (file) => {
    const authHeaders =
      typeof getAuthHeaders === "function" ? await getAuthHeaders() : {};

    const presignResp = await fetch(getApiUrl("/reports/s3/presign/"), {
      method: "POST",
      headers: { ...authHeaders, "Content-Type": "application/json" },
      body: JSON.stringify({ fileName: file.name, contentType: file.type }),
    });

    if (!presignResp.ok) {
      const err = await presignResp.text();
      throw new Error("Presign failed: " + err);
    }
    const { url: presignedUrl, key } = await presignResp.json();

    const putResp = await fetch(presignedUrl, {
      method: "PUT",
      headers: { "Content-Type": file.type },
      body: file,
    });
    if (!putResp.ok) {
      const txt = await putResp.text();
      throw new Error("S3 upload failed: " + txt);
    }

    const S3_BUCKET =
      import.meta.env.VITE_S3_BUCKET || "dev-local-assets-temp";
    const S3_REGION = import.meta.env.VITE_S3_REGION || "ap-south-1";

    const s3ObjectUrl = `https://${S3_BUCKET}.s3.${S3_REGION}.amazonaws.com/${key}`;
    return s3ObjectUrl;
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    setErrors((prev) => ({ ...prev, [name]: "" }));
  };

  const validateForm = () => {
    const newErrors = {};
    let isValid = true;

    if (!formData.issue_title.trim()) {
      newErrors.issue_title = "Title is required";
      isValid = false;
    }

    if (!formData.issue_description.trim()) {
      newErrors.issue_description = "Description is required";
      isValid = false;
    }

    if (!selectedFile && !formData.image_url) {
      newErrors.image = "Image is required";
      isValid = false;
    }

    if (!formData.location) {
      newErrors.location = "Location is required";
      isValid = false;
    }

    setErrors(newErrors);
    return isValid;
  };

  const handleSubmit = async () => {
    if (!validateForm()) {
      alert("Please fill in all required fields");
      return;
    }

    setIsSubmitting(true);

    try {
      let s3Url = formData.image_url;
      if (selectedFile) {
        s3Url = await uploadFileToS3(selectedFile);
      }

      const authHeaders = await getAuthHeaders();

      const reportPayload = {
        issue_title: formData.issue_title,
        issue_description: formData.issue_description,
        location: formData.location,
        image_url: s3Url,
      };

      const response = await fetch(getApiUrl("/reports/"), {
        method: "POST",
        headers: {
          ...authHeaders,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(reportPayload),
      });

      if (response.ok) {
        const data = await response.json();
        setApplicationId(data.tracking_id);
        setShowSuccessPopup(true);
        setFormData({
          issue_title: "",
          location: "",
          issue_description: "",
          image_url: "",
        });
        setSelectedFile(null);
        setPreview(null);
      } else {
        const errorData = await response.json();
        console.error("Error submitting report:", errorData);
        alert(`Error: ${errorData.detail || "Failed to submit report"}`);
      }
    } catch (error) {
      console.error("Error submitting report:", error);
      alert("An error occurred while submitting the report.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const getCurrentDate = () => {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, "0");
    const dd = String(today.getDate()).padStart(2, "0");
    return `${yyyy}-${mm}-${dd}`;
  };

  const customMarkerIcon = L.icon({
    iconUrl:
      "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
    shadowUrl:
      "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41],
  });

  function LocationMarker({ onConfirm }) {
    const [position, setPosition] = useState(tempPosition || [12.9716, 77.5946]);

    const map = useMapEvents({
      click(e) {
        setPosition([e.latlng.lat, e.latlng.lng]);
        setTempPosition([e.latlng.lat, e.latlng.lng]);
        setTempLocation(null);
      },
    });

    useEffect(() => {
      if (position) {
        map.flyTo(position, 13);
      }
    }, [position, map]);

    const handleConfirmClick = async () => {
      if (position) {
        const [lat, lng] = position;
        const address = await reverseGeocode(lat, lng);
        setTempLocation(address);
        onConfirm(address, position);
      }
    };

    return (
      <>
        {position && <Marker position={position} icon={customMarkerIcon} />}
        <div className="leaflet-top leaflet-right" style={{ zIndex: 1000 }}>
          <div className="leaflet-control leaflet-bar">
            <button
              onClick={handleConfirmClick}
              className="bg-emerald-600 text-white px-4 py-2 rounded-lg font-semibold hover:bg-emerald-700 transition shadow-lg"
              style={{
                border: "none",
                cursor: "pointer",
              }}
            >
              Confirm Location
            </button>
          </div>
        </div>
      </>
    );
  }

  const copyToClipboard = async (text) => {
    await navigator.clipboard.writeText(text);
    setCopiedId(true);
    setTimeout(() => setCopiedId(false), 2000);
  };

  const userFields = [
    {
      label: "Full Name",
      value:
        userProfile?.aadhaar?.full_name ||
        `${userProfile?.aadhaar?.first_name || ""} ${
          userProfile?.aadhaar?.last_name || ""
        }`.trim() ||
        "Not available",
      icon: User,
    },
    {
      label: "Email",
      value: userProfile?.email || "Not available",
      icon: Mail,
    },
    {
      label: "Phone",
      value: userProfile?.aadhaar?.phone_number || "Not available",
      icon: Phone,
    },
  ];

  return (
    <div className="min-h-screen flex flex-col bg-white">
      <Navbar />

      {/* Unverified Popup */}
      {showUnverifiedPopup && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full p-8 relative">
            <button
              onClick={() => setShowUnverifiedPopup(false)}
              className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition"
            >
              <X className="w-6 h-6" />
            </button>

            <div className="flex flex-col items-center text-center">
              <div className="w-20 h-20 bg-orange-100 rounded-full flex items-center justify-center mb-6">
                <AlertCircle className="w-10 h-10 text-orange-600" />
              </div>
              
              <h2 className="text-2xl font-black text-gray-900 mb-3">
                Aadhaar Verification Required
              </h2>
              
              <p className="text-gray-600 mb-6 leading-relaxed">
                To ensure authenticity and prevent misuse, all users must complete
                Aadhaar verification before submitting reports.
              </p>

              <button
                onClick={() => (window.location.href = "/profile")}
                className="w-full bg-emerald-600 hover:bg-emerald-700 text-white py-3.5 rounded-lg font-bold transition-all duration-300 shadow-md hover:shadow-lg flex items-center justify-center gap-2"
              >
                Go to Profile
                <ArrowRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Success Popup */}
      {showSuccessPopup && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full p-8 relative">
            <button
              onClick={() => {
                setShowSuccessPopup(false);
                setApplicationId(null);
              }}
              className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition"
            >
              <X className="w-6 h-6" />
            </button>

            <div className="flex flex-col items-center text-center">
              <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mb-6">
                <CheckCircle className="w-10 h-10 text-emerald-600" />
              </div>
              
              <h2 className="text-2xl font-black text-gray-900 mb-3">
                Report Submitted Successfully!
              </h2>
              
              <p className="text-gray-600 mb-6 leading-relaxed">
                Your complaint has been registered. Use the tracking ID below to
                monitor your report's progress.
              </p>

              <div className="w-full bg-emerald-50 border-2 border-emerald-200 rounded-xl p-4 mb-6">
                <p className="text-xs font-semibold text-emerald-700 uppercase tracking-wide mb-2">
                  Tracking ID
                </p>
                <div className="flex items-center justify-between gap-2">
                  <code className="text-xl font-mono font-bold text-emerald-900">
                    {applicationId}
                  </code>
                  <button
                    onClick={() => copyToClipboard(applicationId)}
                    className="p-2 hover:bg-emerald-100 rounded-lg transition"
                    title="Copy to clipboard"
                  >
                    {copiedId ? (
                      <CheckCircle className="w-5 h-5 text-emerald-600" />
                    ) : (
                      <Copy className="w-5 h-5 text-emerald-600" />
                    )}
                  </button>
                </div>
              </div>

              <button
                onClick={() => (window.location.href = "/track")}
                className="w-full bg-emerald-600 hover:bg-emerald-700 text-white py-3.5 rounded-lg font-bold transition-all duration-300 shadow-md hover:shadow-lg flex items-center justify-center gap-2"
              >
                Track Report
                <ArrowRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Map Modal */}
      {showMap && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-4xl h-[80vh] overflow-hidden flex flex-col">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h3 className="text-2xl font-black text-gray-900">
                Select Issue Location
              </h3>
              <button
                onClick={() => setShowMap(false)}
                className="text-gray-400 hover:text-gray-600 transition"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            
            <div className="flex-1 relative">
              <MapContainer
                center={tempPosition || [12.9716, 77.5946]}
                zoom={13}
                style={{ height: "100%", width: "100%" }}
              >
                <TileLayer
                  attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                <LocationMarker
                  onConfirm={(address, pos) => {
                    setFormData((p) => ({ ...p, location: address }));
                    setShowMap(false);
                  }}
                />
              </MapContainer>
            </div>
          </div>
        </div>
      )}

      <main className="flex-grow bg-gradient-to-b from-emerald-50 to-white py-12">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 max-w-6xl">
          <div className="bg-white rounded-2xl shadow-lg p-6 md:p-10">
            {/* Header */}
            <div className="text-center mb-8">
              <h1 className="text-4xl md:text-5xl font-black text-gray-900 mb-3">
                Report an Issue
              </h1>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                Help us improve your community by reporting civic issues. Fill in the
                details below to submit your complaint.
              </p>
            </div>

            <div className="bg-emerald-50 border-2 border-emerald-200 rounded-xl p-4 mb-8 flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-emerald-600 flex-shrink-0 mt-0.5" />
              <p className="text-sm text-emerald-800">
                <strong>Note:</strong> Please ensure that the uploaded image is
                geotagged (contains location data). If your image doesn't have GPS
                data, you can manually select the location on the map.
              </p>
            </div>

            <hr className="my-8 border-gray-200" />

            {/* User Info */}
            <div className="mb-8">
              <div className="flex items-center gap-2 mb-4">
                <User className="w-6 h-6 text-emerald-600" />
                <h2 className="text-2xl font-bold text-gray-900">
                  Your Information
                </h2>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {userFields.map((field, idx) => {
                  const Icon = field.icon;
                  return (
                    <div key={idx} className="bg-gray-50 border border-gray-200 rounded-lg p-4">
                      <div className="flex items-center gap-2 mb-2">
                        <Icon className="w-4 h-4 text-gray-500" />
                        <label className="text-sm font-semibold text-gray-700">
                          {field.label}
                        </label>
                      </div>
                      <p className="text-gray-900 font-medium">{field.value}</p>
                    </div>
                  );
                })}
              </div>

              <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 mt-4">
                <div className="flex items-center gap-2 mb-2">
                  <Calendar className="w-4 h-4 text-gray-500" />
                  <label className="text-sm font-semibold text-gray-700">
                    Issue Date
                  </label>
                </div>
                <p className="text-gray-900 font-medium">
                  {new Date(getCurrentDate()).toLocaleDateString("en-IN", {
                    day: "2-digit",
                    month: "long",
                    year: "numeric",
                  })}
                </p>
              </div>
            </div>

            <hr className="my-8 border-gray-200" />

            {/* Issue Details */}
            <div className="mb-8">
              <div className="flex items-center gap-2 mb-6">
                <FileText className="w-6 h-6 text-emerald-600" />
                <h2 className="text-2xl font-bold text-gray-900">
                  Issue Details
                </h2>
              </div>

              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Left side - Text inputs */}
                <div className="lg:col-span-2 space-y-6">
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">
                      Issue Title <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      name="issue_title"
                      placeholder="Briefly describe the issue (e.g., 'Broken streetlight on MG Road')"
                      value={formData.issue_title}
                      onChange={handleInputChange}
                      maxLength={80}
                      className="w-full px-4 py-3 bg-white border border-gray-300 text-gray-900 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 transition-all"
                    />
                    <div className="flex justify-between items-center mt-2">
                      <span className="text-xs text-gray-500">
                        {formData.issue_title.length}/80 characters
                      </span>
                      {errors.issue_title && (
                        <span className="text-xs text-red-600 font-semibold">
                          {errors.issue_title}
                        </span>
                      )}
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">
                      Issue Description <span className="text-red-500">*</span>
                    </label>
                    <textarea
                      name="issue_description"
                      value={formData.issue_description}
                      onChange={handleInputChange}
                      placeholder="Provide detailed information about the issue, including when you noticed it and any relevant details..."
                      maxLength={500}
                      required
                      className="w-full px-4 py-3 bg-white border border-gray-300 text-gray-900 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 resize-none h-40 transition-all"
                    />
                    <div className="flex justify-between items-center mt-2">
                      <span
                        className={`text-xs ${
                          formData.issue_description.length > 450
                            ? "text-orange-600 font-semibold"
                            : "text-gray-500"
                        }`}
                      >
                        {formData.issue_description.length}/500 characters
                      </span>
                      {errors.issue_description && (
                        <span className="text-xs text-red-600 font-semibold">
                          {errors.issue_description}
                        </span>
                      )}
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2">
                      <MapPin className="w-4 h-4 text-emerald-600" />
                      Issue Location <span className="text-red-500">*</span>
                      {formData.location && !geotagWarning && (
                        <span className="text-xs font-normal text-emerald-600 ml-2">
                          ✓ Auto-detected from image
                        </span>
                      )}
                    </label>
                    <div className="flex gap-2">
                      <input
                        type="text"
                        name="location"
                        value={formData.location}
                        readOnly
                        required
                        placeholder="Auto-detected from geotagged image or manually selected"
                        className="flex-1 px-4 py-3 bg-gray-50 border border-gray-300 text-gray-700 rounded-lg cursor-not-allowed"
                      />
                      <button
                        type="button"
                        onClick={() => setShowMap(true)}
                        className="px-6 py-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-semibold transition-all shadow-sm hover:shadow-md"
                      >
                        Select on Map
                      </button>
                    </div>
                    {errors.location && (
                      <p className="text-xs text-red-600 font-semibold mt-2">
                        {errors.location}
                      </p>
                    )}
                  </div>
                </div>

                {/* Right side - Image upload */}
                <div className="bg-gradient-to-br from-emerald-50 to-green-50 border-2 border-emerald-200 rounded-xl p-6 flex flex-col">
                  <div className="flex items-center justify-between mb-3">
                    <label className="text-sm font-semibold text-gray-900">
                      Issue Image <span className="text-red-500">*</span>
                    </label>
                    {isExtractingLocation && (
                      <span className="text-xs text-emerald-600 font-semibold animate-pulse flex items-center gap-1">
                        <MapPin className="w-3 h-3" />
                        Extracting GPS...
                      </span>
                    )}
                  </div>

                  <a
                    href="https://www.precisely.com/glossary/geotagging/"
                    className="text-xs text-emerald-700 hover:text-emerald-800 underline mb-4 inline-block"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    What is geotagging?
                  </a>

                  <div className="flex-1 border-2 border-dashed border-emerald-300 rounded-xl bg-white min-h-[280px] flex items-center justify-center overflow-hidden">
                    {preview ? (
                      <img
                        src={preview}
                        alt="Preview"
                        className="w-full h-full object-contain"
                      />
                    ) : (
                      <div className="flex flex-col items-center text-emerald-600">
                        <ImageIcon className="w-12 h-12 mb-2 opacity-50" />
                        <span className="text-sm font-medium opacity-75">
                          No image selected
                        </span>
                      </div>
                    )}
                  </div>

                  <div className="mt-4 space-y-3">
                    <label
                      htmlFor="fileInput"
                      className="cursor-pointer bg-white hover:bg-gray-50 border-2 border-emerald-600 text-emerald-600 px-4 py-3 rounded-lg flex items-center justify-center gap-2 font-semibold transition-all shadow-sm hover:shadow-md"
                    >
                      <ImageIcon className="w-5 h-5" />
                      Choose Image
                    </label>

                    <input
                      id="fileInput"
                      type="file"
                      accept="image/*"
                      onChange={handleFileChange}
                      className="hidden"
                    />

                    {selectedFile && (
                      <p className="text-xs text-gray-700 text-center truncate">
                        📎 {selectedFile.name}
                      </p>
                    )}

                    {geotagWarning && (
                      <div className="bg-orange-50 border border-orange-300 rounded-lg p-3">
                        <p className="text-xs text-orange-700 font-medium">
                          {geotagWarning}
                        </p>
                        <p className="text-xs text-orange-600 mt-1">
                          💡 Tip: Use your phone's camera with location enabled
                        </p>
                      </div>
                    )}

                    {errors.image && (
                      <p className="text-xs text-red-600 font-semibold text-center">
                        {errors.image}
                      </p>
                    )}
                  </div>
                </div>
              </div>
            </div>

            <hr className="my-8 border-gray-200" />

            {/* Submit Button */}
            <div className="flex justify-center">
              <button
                onClick={handleSubmit}
                disabled={isSubmitting}
                className="group bg-emerald-600 hover:bg-emerald-700 text-white px-10 py-4 rounded-lg font-bold text-lg transition-all duration-300 shadow-lg hover:shadow-xl hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100 flex items-center gap-3"
              >
                {isSubmitting ? (
                  <>
                    <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    Submitting Report...
                  </>
                ) : (
                  <>
                    Submit Report
                    <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}

export default Report;