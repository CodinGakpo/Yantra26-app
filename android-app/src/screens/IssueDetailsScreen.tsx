import React from 'react';
import {View, Text, StyleSheet, ScrollView, Image} from 'react-native';
import {IssueReport} from '../shared/api/reportApi';

/**
 * Issue Details Screen
 * Shows detailed information about a specific report
 */
export default function IssueDetailsScreen({route}: any) {
  const {report}: {report: IssueReport} = route.params;

  return (
    <ScrollView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>{report.issue_title}</Text>

        {report.tracking_id && (
          <View style={styles.infoCard}>
            <Text style={styles.infoLabel}>Tracking ID</Text>
            <Text style={styles.trackingId}>{report.tracking_id}</Text>
          </View>
        )}

        {report.status && (
          <View style={styles.statusCard}>
            <Text style={styles.infoLabel}>Status</Text>
            <View style={styles.statusBadge}>
              <Text style={styles.statusText}>{report.status}</Text>
            </View>
          </View>
        )}

        <View style={styles.infoCard}>
          <Text style={styles.infoLabel}>Location</Text>
          <Text style={styles.infoText}>{report.location}</Text>
        </View>

        <View style={styles.infoCard}>
          <Text style={styles.infoLabel}>Description</Text>
          <Text style={styles.descriptionText}>{report.issue_description}</Text>
        </View>

        {report.image_url && (
          <View style={styles.imageCard}>
            <Text style={styles.infoLabel}>Image</Text>
            <Image
              source={{uri: report.image_url}}
              style={styles.image}
              resizeMode="cover"
            />
          </View>
        )}

        {report.created_at && (
          <View style={styles.infoCard}>
            <Text style={styles.infoLabel}>Submitted</Text>
            <Text style={styles.infoText}>
              {new Date(report.created_at).toLocaleString()}
            </Text>
          </View>
        )}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  content: {
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 16,
  },
  infoCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  statusCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  imageCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  infoLabel: {
    fontSize: 12,
    color: '#999',
    fontWeight: '600',
    textTransform: 'uppercase',
    marginBottom: 8,
  },
  infoText: {
    fontSize: 16,
    color: '#000',
  },
  trackingId: {
    fontSize: 16,
    color: '#007AFF',
    fontWeight: '600',
  },
  descriptionText: {
    fontSize: 16,
    color: '#000',
    lineHeight: 24,
  },
  statusBadge: {
    alignSelf: 'flex-start',
    backgroundColor: '#007AFF',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  statusText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  image: {
    width: '100%',
    height: 300,
    borderRadius: 8,
  },
});
