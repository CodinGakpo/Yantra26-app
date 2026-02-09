import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  ActivityIndicator,
  Alert,
  Image,
} from 'react-native';
import {launchImageLibrary} from 'react-native-image-picker';
import {useAuth} from '../shared/context/AuthContext';
import {reportApi, ReportData} from '../shared/api/reportApi';
import {userApi} from '../shared/api/userApi';

/**
 * Report Screen
 * Converted from web Report.jsx
 * Allows users to submit issue reports with images
 * 
 * TODO: 
 * - Implement map location picker (react-native-maps)
 * - Add AI image classification integration
 * - Upload image to backend
 */
export default function ReportScreen({navigation}: any) {
  const {user} = useAuth();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [userProfile, setUserProfile] = useState<any>(null);
  const [selectedImage, setSelectedImage] = useState<any>(null);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [trackingId, setTrackingId] = useState('');

  const [formData, setFormData] = useState<ReportData>({
    issue_title: '',
    location: '',
    issue_description: '',
    image_url: '',
  });

  const [errors, setErrors] = useState({
    issue_title: '',
    issue_description: '',
    location: '',
  });

  useEffect(() => {
    fetchUserProfile();
  }, []);

  const fetchUserProfile = async () => {
    try {
      const profile = await userApi.getProfile();
      setUserProfile(profile);

      // Check if user is verified
      if (!user?.is_verified) {
        Alert.alert(
          'Verification Required',
          'Please verify your account to submit reports',
          [
            {
              text: 'Go to Profile',
              onPress: () => navigation.navigate('Profile'),
            },
            {text: 'Cancel', style: 'cancel'},
          ],
        );
      }
    } catch (error) {
      console.error('Failed to fetch profile:', error);
    }
  };

  const handleImagePick = () => {
    launchImageLibrary(
      {
        mediaType: 'photo',
        quality: 0.8,
        maxWidth: 1024,
        maxHeight: 1024,
      },
      (response: any) => {
        if (response.didCancel) {
          return;
        }
        if (response.errorCode) {
          Alert.alert('Error', 'Failed to pick image');
          return;
        }
        if (response.assets && response.assets[0]) {
          setSelectedImage(response.assets[0]);
        }
      },
    );
  };

  const validateForm = (): boolean => {
    const newErrors = {
      issue_title: '',
      issue_description: '',
      location: '',
    };

    if (!formData.issue_title.trim()) {
      newErrors.issue_title = 'Issue title is required';
    } else if (formData.issue_title.length < 10) {
      newErrors.issue_title = 'Issue title must be at least 10 characters';
    }

    if (!formData.issue_description.trim()) {
      newErrors.issue_description = 'Description is required';
    } else if (formData.issue_description.length < 20) {
      newErrors.issue_description =
        'Description must be at least 20 characters';
    }

    if (!formData.location.trim()) {
      newErrors.location = 'Location is required';
    }

    setErrors(newErrors);
    return !Object.values(newErrors).some(error => error !== '');
  };

  const handleSubmit = async () => {
    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);

    try {
      // TODO: Upload image first if selected
      // const imageUrl = await uploadImage(selectedImage);

      const reportData: ReportData = {
        ...formData,
        image_url: selectedImage?.uri || '',
      };

      const response = await reportApi.createReport(reportData);

      setTrackingId(response.tracking_id || '');
      setShowSuccessModal(true);

      // Reset form
      setFormData({
        issue_title: '',
        location: '',
        issue_description: '',
        image_url: '',
      });
      setSelectedImage(null);
    } catch (error: any) {
      Alert.alert(
        'Submission Failed',
        error?.response?.data?.detail || 'Failed to submit report',
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const updateField = (field: keyof ReportData, value: string) => {
    setFormData((prev: any) => ({...prev, [field]: value}));
    setErrors((prev: any) => ({...prev, [field]: ''}));
  };

  if (showSuccessModal) {
    return (
      <View style={styles.successContainer}>
        <View style={styles.successModal}>
          <Text style={styles.successTitle}>Report Submitted!</Text>
          <Text style={styles.successText}>
            Your report has been submitted successfully.
          </Text>
          <Text style={styles.trackingText}>Tracking ID: {trackingId}</Text>
          <Pressable
            style={styles.successButton}
            onPress={() => {
              setShowSuccessModal(false);
              navigation.navigate('Track');
            }}>
            <Text style={styles.successButtonText}>Track Report</Text>
          </Pressable>
          <Pressable
            style={styles.dismissButton}
            onPress={() => setShowSuccessModal(false)}>
            <Text style={styles.dismissButtonText}>Close</Text>
          </Pressable>
        </View>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled">
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Submit Report</Text>
          <Text style={styles.headerSubtitle}>Report a community issue</Text>
        </View>

        <View style={styles.form}>
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Issue Title *</Text>
            <TextInput
              style={[styles.input, errors.issue_title && styles.inputError]}
              placeholder="Brief title of the issue"
              placeholderTextColor="#999"
              value={formData.issue_title}
              onChangeText={(text: string) => updateField('issue_title', text)}
              editable={!isSubmitting}
            />
            {errors.issue_title ? (
              <Text style={styles.errorText}>{errors.issue_title}</Text>
            ) : null}
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Location *</Text>
            <TextInput
              style={[styles.input, errors.location && styles.inputError]}
              placeholder="Enter location"
              placeholderTextColor="#999"
              value={formData.location}
              onChangeText={(text: string) => updateField('location', text)}
              editable={!isSubmitting}
            />
            <Text style={styles.hint}>
              TODO: Add map picker for precise location
            </Text>
            {errors.location ? (
              <Text style={styles.errorText}>{errors.location}</Text>
            ) : null}
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Description *</Text>
            <TextInput
              style={[
                styles.textArea,
                errors.issue_description && styles.inputError,
              ]}
              placeholder="Describe the issue in detail"
              placeholderTextColor="#999"
              value={formData.issue_description}
              onChangeText={(text: string) => updateField('issue_description', text)}
              multiline
              numberOfLines={6}
              textAlignVertical="top"
              editable={!isSubmitting}
            />
            {errors.issue_description ? (
              <Text style={styles.errorText}>{errors.issue_description}</Text>
            ) : null}
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Upload Image</Text>
            {selectedImage ? (
              <View style={styles.imagePreviewContainer}>
                <Image
                  source={{uri: selectedImage.uri}}
                  style={styles.imagePreview}
                />
                <Pressable
                  style={styles.removeImageButton}
                  onPress={() => setSelectedImage(null)}>
                  <Text style={styles.removeImageText}>Remove</Text>
                </Pressable>
              </View>
            ) : (
              <Pressable
                style={styles.uploadButton}
                onPress={handleImagePick}
                disabled={isSubmitting}>
                <Text style={styles.uploadButtonText}>Choose Image</Text>
              </Pressable>
            )}
          </View>

          <Pressable
            style={({pressed}: any) => [
              styles.submitButton,
              pressed && styles.buttonPressed,
              isSubmitting && styles.buttonDisabled,
            ]}
            onPress={handleSubmit}
            disabled={isSubmitting}>
            {isSubmitting ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.submitButtonText}>Submit Report</Text>
            )}
          </Pressable>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
  },
  header: {
    marginBottom: 24,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 4,
  },
  headerSubtitle: {
    fontSize: 16,
    color: '#666',
  },
  form: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  inputGroup: {
    marginBottom: 20,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#000',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#f9f9f9',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 14,
    fontSize: 16,
    color: '#000',
  },
  textArea: {
    backgroundColor: '#f9f9f9',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 14,
    fontSize: 16,
    color: '#000',
    minHeight: 120,
  },
  inputError: {
    borderColor: '#ff4444',
  },
  errorText: {
    color: '#ff4444',
    fontSize: 12,
    marginTop: 4,
  },
  hint: {
    fontSize: 12,
    color: '#999',
    marginTop: 4,
  },
  uploadButton: {
    backgroundColor: '#f0f0f0',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 16,
    alignItems: 'center',
  },
  uploadButtonText: {
    color: '#007AFF',
    fontSize: 16,
    fontWeight: '600',
  },
  imagePreviewContainer: {
    alignItems: 'center',
  },
  imagePreview: {
    width: '100%',
    height: 200,
    borderRadius: 8,
    resizeMode: 'cover',
  },
  removeImageButton: {
    marginTop: 8,
    padding: 8,
  },
  removeImageText: {
    color: '#ff4444',
    fontSize: 14,
  },
  submitButton: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    padding: 16,
    alignItems: 'center',
    marginTop: 12,
  },
  buttonPressed: {
    opacity: 0.8,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  submitButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  successContainer: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  successModal: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 32,
    width: '100%',
    maxWidth: 400,
    alignItems: 'center',
  },
  successTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 12,
  },
  successText: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    marginBottom: 16,
  },
  trackingText: {
    fontSize: 14,
    color: '#007AFF',
    fontWeight: '600',
    marginBottom: 24,
  },
  successButton: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    padding: 16,
    width: '100%',
    alignItems: 'center',
    marginBottom: 12,
  },
  successButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  dismissButton: {
    padding: 12,
  },
  dismissButtonText: {
    color: '#666',
    fontSize: 14,
  },
});
