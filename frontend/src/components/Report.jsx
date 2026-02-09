import { useState, useEffect } from "react";
import Navbar from "./MiniNavbar";
import folder from "../assets/foldericon.png";
import { useAuth } from "../AuthProvider";
import Footer from "./Footer";
import Tick from "../assets/tick.png";
import Copy from "../assets/copy.jpg";
import Logo from "../assets/logo-1.png";
import { classifyImage } from "../ai/classifyImage";
import {
  User,
  FileText,
  Image as ImageIcon,
  MapPin,
  AlertCircle,
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

  // Extract geolocation from image EXIF data - IMPROVED VERSION
  const extractGeolocation = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      
      reader.onload = function (e) {
        const image = new Image();
        image.src = e.target.result;
        
        image.onload = function () {
          EXIF.getData(image, function () {
            const allTags = EXIF.getAllTags(this);
            console.log("All EXIF tags:", allTags); // Debug log
            
            const lat = EXIF.getTag(this, "GPSLatitude");
            const latRef = EXIF.getTag(this, "GPSLatitudeRef");
            const lon = EXIF.getTag(this, "GPSLongitude");
            const lonRef = EXIF.getTag(this, "GPSLongitudeRef");

            console.log("GPS Data:", { lat, latRef, lon, lonRef }); // Debug log

            if (lat && lon && latRef && lonRef) {
              const latitude = convertDMSToDD(lat[0], lat[1], lat[2], latRef);
              const longitude = convertDMSToDD(lon[0], lon[1], lon[2], lonRef);
              
              console.log("Converted coordinates:", { latitude, longitude }); // Debug log
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
      // Fallback to coordinates if reverse geocoding fails
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
        
        console.log("Successfully extracted GPS:", { latitude, longitude }); // Debug log
        
        // Get human-readable address
        const address = await reverseGeocode(latitude, longitude);
        
        console.log("Geocoded address:", address); // Debug log
        
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
      import.meta.env.VITE_S3_BUCKET || "reportmitra-report-images-dc";
    const AWS_REGION = import.meta.env.VITE_AWS_REGION || "ap-south-1";

    return { key };
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((p) => ({ ...p, [name]: value }));
    setErrors((p) => ({ ...p, [name]: "" }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrors({
      issue_title: "",
      issue_description: "",
      image: "",
      location: "",
    });

    if (!userProfile?.is_aadhaar_verified) {
      setShowUnverifiedPopup(true);
      return;
    }

    function fileToBase64(file) {
      return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result);
        reader.onerror = reject;
        reader.readAsDataURL(file);
      });
    }

    let hasError = false;
    if (!formData.issue_title.trim()) {
      setErrors((p) => ({ ...p, issue_title: "Issue title is required" }));
      hasError = true;
    }
    if (!formData.issue_description.trim()) {
      setErrors((p) => ({
        ...p,
        issue_description: "Issue description is required",
      }));
      hasError = true;
    }
    if (!selectedFile) {
      setErrors((p) => ({ ...p, image: "Issue image is required" }));
      hasError = true;
    }
    if (!formData.location) {
      setErrors((p) => ({
        ...p,
        location: "Please choose the issue location",
      }));
      hasError = true;
    }
    if (hasError) {
      setIsSubmitting(false);
      return;
    }
    setIsSubmitting(true);

    try {
      if (!user) {
        alert("Please log in before submitting a report.");
        setIsSubmitting(false);
        return;
      }

      if (!userProfile) {
        alert("Profile data is still loading. Please wait and try again.");
        setIsSubmitting(false);
        return;
      }

      let imageUrl = formData.image_url || "";

      if (selectedFile) {
        try {
          const { key } = await uploadFileToS3(selectedFile);
          imageUrl = key;

          if (import.meta.env.DEV) {
            console.log("Uploaded image URL:", imageUrl);
          }
        } catch (uploadErr) {
          console.error("Image upload error:", uploadErr);
          alert("Failed to upload image. Please try again.");
          setIsSubmitting(false);
          return;
        }
      }
      let department = "Manual";
      if (selectedFile) {
        try {
          const base64 = await fileToBase64(selectedFile);
          department = await classifyImage(base64);
          if (import.meta.env.DEV) {
            console.log("AI Department:", department);
          }
        } catch (err) {
          console.error("Classification failed:", err);
        }
      }

      const headers =
        typeof getAuthHeaders === "function"
          ? await getAuthHeaders()
          : { "Content-Type": "application/json" };

      const payload = {
        issue_title: formData.issue_title,
        location: formData.location,
        issue_description: formData.issue_description,
        image_url: imageUrl,
        department: department,
        status: "pending",
      };

      const response = await fetch(getApiUrl("/reports/"), {
        method: "POST",
        headers: {
          ...headers,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error("Error response:", errorText);
        throw new Error("Failed to submit report");
      }

      const result = await response.json();
      setApplicationId(result.tracking_id);
      setShowSuccessPopup(true);

      setFormData({
        issue_title: "",
        location: "",
        issue_description: "",
        image_url: "",
      });
      setSelectedFile(null);
      setPreview(null);
      setGeotagWarning("");
    } catch (error) {
      console.error("Submission error:", error);
      alert("An error occurred while submitting the report. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const MapClickHandler = () => {
    useMapEvents({
      click: async (e) => {
        const { lat, lng } = e.latlng;
        setTempPosition([lat, lng]);

        // Reverse geocode the clicked position
        try {
          const address = await reverseGeocode(lat, lng);
          setTempLocation(address);
        } catch (error) {
          console.error("Error getting address:", error);
          setTempLocation(`${lat.toFixed(6)}, ${lng.toFixed(6)}`);
        }
      },
    });
    return null;
  };

  const handleMapConfirm = () => {
    if (tempLocation && tempPosition) {
      setFormData((p) => ({ ...p, location: tempLocation }));
      setShowMap(false);
      setErrors((p) => ({ ...p, location: "" }));
      setGeotagWarning("");
    }
  };

  const handleMapCancel = () => {
    setShowMap(false);
    setTempLocation(null);
    setTempPosition(null);
  };

  const getCurrentDate = () => {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, "0");
    const dd = String(today.getDate()).padStart(2, "0");
    return `${yyyy}-${mm}-${dd}`;
  };

  const firstNameDisplay = userProfile?.first_name || "Loading...";
  const middleNameDisplay = userProfile?.middle_name || "N/A";
  const lastNameDisplay = userProfile?.last_name || "Loading...";

  const handleCopy = () => {
    navigator.clipboard.writeText(applicationId);
  };

  return (
    <div className="min-h-screen flex flex-col">
      <Navbar />

      {showUnverifiedPopup && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-lg shadow-xl p-6 max-w-md w-full">
            <div className="flex items-center gap-3 mb-4">
              <div className="bg-red-100 p-2 rounded-full">
                <AlertCircle className="w-6 h-6 text-red-600" />
              </div>
              <h2 className="text-xl font-bold text-gray-900">
                Verification Required
              </h2>
            </div>
            <p className="text-gray-600 mb-6">
              You must complete Aadhaar verification before submitting a report.
              Please verify your identity to continue.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowUnverifiedPopup(false)}
                className="flex-1 px-4 py-2 bg-gray-200 text-gray-800 rounded-md hover:bg-gray-300 transition"
              >
                Close
              </button>
              <button
                onClick={() => (window.location.href = "/profile")}
                className="flex-1 px-4 py-2 bg-black text-white rounded-md hover:bg-gray-800 transition"
              >
                Verify Now
              </button>
            </div>
          </div>
        </div>
      )}

      {showSuccessPopup && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-lg shadow-xl p-6 max-w-md w-full">
            <div className="flex flex-col items-center text-center">
              <div className="bg-green-100 p-4 rounded-full mb-4">
                <img src={Tick} alt="Success" className="w-12 h-12" />
              </div>
              <h2 className="text-2xl font-bold text-gray-900 mb-2">
                Report Submitted Successfully!
              </h2>
              <p className="text-gray-600 mb-4">
                Your issue has been registered. Please save your tracking ID:
              </p>

              <div className="bg-gray-50 border-2 border-dashed border-gray-300 rounded-lg p-4 w-full mb-4">
                <div className="flex items-center justify-between">
                  <span className="font-mono text-lg font-bold text-gray-900">
                    {applicationId}
                  </span>
                  <button
                    onClick={handleCopy}
                    className="p-2 hover:bg-gray-200 rounded transition"
                    title="Copy to clipboard"
                  >
                    <img src={Copy} alt="Copy" className="w-5 h-5" />
                  </button>
                </div>
              </div>

              <p className="text-sm text-gray-500 mb-6">
                Use this ID to track your report status
              </p>

              <button
                onClick={() => {
                  setShowSuccessPopup(false);
                  setApplicationId(null);
                }}
                className="w-full px-6 py-3 bg-black text-white rounded-md hover:bg-gray-800 transition font-semibold"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {showMap && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
            <div className="p-4 border-b flex justify-between items-center">
              <h2 className="text-xl font-bold text-gray-900">
                Select Issue Location
              </h2>
              <button
                onClick={handleMapCancel}
                className="text-gray-500 hover:text-gray-700"
              >
                ✕
              </button>
            </div>

            <div className="flex-1 relative">
              <MapContainer
                center={tempPosition || [11.0168, 76.9558]}
                zoom={13}
                className="h-full w-full"
              >
                <TileLayer
                  attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                <MapClickHandler />
                {tempPosition && (
                  <Marker
                    position={tempPosition}
                    icon={L.icon({
                      iconUrl:
                        "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
                      iconSize: [25, 41],
                      iconAnchor: [12, 41],
                    })}
                  />
                )}
              </MapContainer>
            </div>

            <div className="p-4 border-t space-y-3">
              {tempLocation ? (
                <div className="bg-gray-50 p-3 rounded-md">
                  <p className="text-sm font-semibold text-gray-700 mb-1">
                    Selected Location:
                  </p>
                  <p className="text-sm text-gray-600">{tempLocation}</p>
                </div>
              ) : (
                <p className="text-sm text-gray-500 text-center">
                  Click on the map to select a location
                </p>
              )}

              <div className="flex gap-3">
                <button
                  onClick={handleMapCancel}
                  className="flex-1 px-4 py-2 bg-gray-200 text-gray-800 rounded-md hover:bg-gray-300 transition"
                >
                  Cancel
                </button>
                <button
                  onClick={handleMapConfirm}
                  disabled={!tempLocation}
                  className="flex-1 px-4 py-2 bg-black text-white rounded-md hover:bg-gray-800 transition disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Confirm Location
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      <main className="flex-grow bg-gray-50 flex justify-center py-8 md:py-12">
        <div
          className="bg-white w-full max-w-6xl rounded-2xl shadow-md
          px-4 sm:px-6 md:px-10 py-6 md:py-8"
        >
          <h1 className="text-center font-extrabold text-3xl md:text-5xl mb-6">
            Issue a Report
          </h1>

          <div className="flex-1 flex flex-col justify-center">
            <div className="flex items-center gap-2 mb-4">
              <User className="w-5 h-5 text-gray-700" />
              <h2 className="text-lg font-semibold text-gray-800">
                Citizen Details
              </h2>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
              {[
                {
                  label: "First Name",
                  value: firstNameDisplay,
                },
                {
                  label: "Middle Name",
                  value: middleNameDisplay,
                },
                {
                  label: "Last Name",
                  value: lastNameDisplay,
                },
              ].map((f) => (
                <div key={f.label} className="flex flex-col font-bold">
                  <label>{f.label}</label>
                  <input
                    type="text"
                    readOnly
                    value={f.value}
                    className="border px-2 py-1 rounded-md text-gray-500"
                  />
                </div>
              ))}

              <div className="flex flex-col font-bold">
                <label>Issue Date</label>
                <input
                  type="date"
                  readOnly
                  value={getCurrentDate()}
                  className="border px-2 py-1 rounded-md text-gray-500"
                />
              </div>
            </div>

            <hr className="my-4" />

            <div className="flex items-center gap-2 mb-4 mt-6">
              <FileText className="w-5 h-5 text-gray-700" />
              <h2 className="text-lg font-semibold text-gray-800">
                Issue Details
              </h2>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-5 gap-8 mb-6">
              <div className="md:col-span-3 flex flex-col font-bold space-y-2">
                <label>Issue Title</label>
                <input
                  type="text"
                  name="issue_title"
                  placeholder="Briefly name the issue"
                  value={formData.issue_title}
                  onChange={handleInputChange}
                  maxLength={80}
                  className="border px-3 py-2 rounded-md placeholder:text-gray-500"
                />

                <div className="flex justify-between text-xs mt-1">
                  <span className="text-gray-500">
                    {formData.issue_title.length}/80 characters
                  </span>
                  {errors.issue_title && (
                    <span className="text-red-600">{errors.issue_title}</span>
                  )}
                </div>

                <label>Issue Description</label>
                <textarea
                  name="issue_description"
                  value={formData.issue_description}
                  onChange={handleInputChange}
                  placeholder="Describe the issue in detail"
                  maxLength={500}
                  required
                  className="border px-3 py-2 rounded-md placeholder:text-gray-500 resize-none h-44 lg:h-56"
                />

                <div className="flex justify-between text-xs mt-1">
                  <span
                    className={
                      formData.issue_description.length > 450
                        ? "text-orange-600"
                        : "text-gray-500"
                    }
                  >
                    {formData.issue_description.length}/500 characters
                  </span>

                  {errors.issue_description && (
                    <span className="text-red-600">
                      {errors.issue_description}
                    </span>
                  )}
                </div>
              </div>

              <div
                className="md:col-span-2 flex flex-col font-bold space-y-4
  bg-gray-50 border rounded-xl p-4 h-full"
              >
                <div className="flex items-center justify-between">
                  <label>Issue Image (Geotagged)</label>
                  {isExtractingLocation && (
                    <span className="text-xs text-blue-600 animate-pulse">
                      📍 Extracting...
                    </span>
                  )}
                </div>
                <a
                  href="https://www.precisely.com/glossary/geotagging/"
                  className="underline text-sm text-blue-700 -mt-1"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  What is geotagging?
                </a>

                <div
                  className="border-2 border-dashed border-gray-300 rounded-xl
  flex-1 min-h-[220px] lg:min-h-[260px]
  flex flex-col items-center justify-center gap-2
  text-gray-500 overflow-hidden bg-white"
                >
                  {preview ? (
                    <img
                      src={preview}
                      alt="Preview"
                      className="object-contain w-full h-full rounded-xl"
                    />
                  ) : (
                    <>
                      <ImageIcon className="w-6 h-6 opacity-60" />
                      <span className="text-xs text-gray-400">
                        No image selected
                      </span>
                    </>
                  )}
                </div>

                <div className="flex flex-col gap-2">
                  <label
                    htmlFor="fileInput"
                    className="cursor-pointer bg-white border-2 border-gray-400 px-4 py-2.5 rounded-md
  flex items-center justify-center gap-2 text-sm font-semibold
  hover:bg-gray-50 hover:border-gray-400 transition"
                  >
                    <img src={folder} alt="" className="h-4 w-4" />
                    Choose File
                  </label>

                  <input
                    id="fileInput"
                    type="file"
                    accept="image/*"
                    onChange={handleFileChange}
                    className="hidden"
                  />

                  {selectedFile && (
                    <span className="text-xs text-gray-600 text-center truncate">
                      {selectedFile.name}
                    </span>
                  )}
                  {geotagWarning && (
                    <div className="bg-orange-50 border border-orange-200 rounded-md p-2">
                      <p className="text-orange-600 text-xs font-normal text-center">
                        {geotagWarning}
                      </p>
                      <p className="text-orange-500 text-xs text-center mt-1">
                        💡 Tip: Use your phone's camera app to take photos with location enabled
                      </p>
                    </div>
                  )}
                  {errors.image && (
                    <p className="text-red-600 text-sm font-normal text-center">
                      {errors.image}
                    </p>
                  )}
                </div>
              </div>
            </div>

            <div
              className="flex flex-col md:flex-row justify-between items-center
              border-t pt-6 mt-6 gap-4"
            >
              <div className="flex flex-col gap-2 font-bold w-full md:max-w-[60%]">
                <label className="whitespace-nowrap flex items-center gap-1">
                  <MapPin className="w-4 h-4 text-gray-600" />
                  Issue Location
                  {formData.location && !geotagWarning && (
                    <span className="text-xs font-normal text-green-600 ml-2">
                      ✓ Auto-detected from image
                    </span>
                  )}
                </label>

                <div className="flex gap-2 w-full">
                  <input
                    type="text"
                    name="location"
                    value={formData.location}
                    readOnly
                    required
                    placeholder="Auto-detected from geotagged image or use map"
                    className="border px-3 py-2 rounded-md w-full
      bg-gray-100 text-gray-600 cursor-not-allowed"
                  />

                  <button
                    type="button"
                    onClick={() => setShowMap(true)}
                    className="px-4 py-2 bg-gray-800 text-white rounded-md hover:bg-black"
                  >
                    Choose
                  </button>
                </div>
                {errors.location && (
                  <p className="text-red-600 text-sm font-normal mt-1">
                    {errors.location}
                  </p>
                )}
              </div>

              <button
                onClick={handleSubmit}
                disabled={isSubmitting}
                className="px-6 py-2 bg-black text-white rounded-xl text-lg font-bold hover:scale-105 transition disabled:opacity-50"
              >
                {isSubmitting ? "Submitting..." : "Submit Report"}
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