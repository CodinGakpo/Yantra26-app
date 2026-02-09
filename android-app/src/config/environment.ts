/**
 * Environment Configuration
 * 
 * For Android Emulator:
 * - Use 10.0.2.2 to access localhost on the host machine
 * - This is the special alias Android provides for the host
 * 
 * For physical device:
 * - Replace with your computer's IP address (e.g., 192.168.1.X:8000)
 * 
 * TODO: Consider using react-native-config for multiple environments
 */

export const API_BASE_URL = 'http://10.0.2.2:8000/api';

export const Config = {
  API_BASE_URL,
  // Add other config values as needed
};
