import React, {useState} from 'react';
import {
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  ActivityIndicator,
  Alert,
} from 'react-native';
import {reportApi, IssueReport} from '../shared/api/reportApi';

/**
 * Track Screen
 * Allows users to track reports by tracking ID
 */
export default function TrackScreen({navigation}: any) {
  const [trackingId, setTrackingId] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleTrack = async () => {
    if (!trackingId.trim()) {
      Alert.alert('Error', 'Please enter a tracking ID');
      return;
    }

    setIsLoading(true);
    try {
      const report = await reportApi.getReportByTrackingId(trackingId);
      navigation.navigate('IssueDetails', {report});
    } catch (error: any) {
      Alert.alert(
        'Not Found',
        'No report found with this tracking ID',
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Track Report</Text>
      </View>

      <View style={styles.content}>
        <Text style={styles.instructionText}>
          Enter your tracking ID to check the status of your report
        </Text>

        <View style={styles.inputContainer}>
          <Text style={styles.label}>Tracking ID</Text>
          <TextInput
            style={styles.input}
            placeholder="Enter tracking ID"
            placeholderTextColor="#999"
            value={trackingId}
            onChangeText={setTrackingId}
            autoCapitalize="characters"
            editable={!isLoading}
          />
        </View>

        <Pressable
          style={({pressed}: any) => [
            styles.trackButton,
            pressed && styles.buttonPressed,
            isLoading && styles.buttonDisabled,
          ]}
          onPress={handleTrack}
          disabled={isLoading}>
          {isLoading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.trackButtonText}>Track</Text>
          )}
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    backgroundColor: '#fff',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#ddd',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#000',
  },
  content: {
    padding: 16,
  },
  instructionText: {
    fontSize: 16,
    color: '#666',
    marginBottom: 24,
    lineHeight: 24,
  },
  inputContainer: {
    marginBottom: 24,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#000',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 16,
    fontSize: 16,
    color: '#000',
  },
  trackButton: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    padding: 16,
    alignItems: 'center',
  },
  trackButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  buttonPressed: {
    opacity: 0.8,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
});
