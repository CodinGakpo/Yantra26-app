import React from 'react';
import {View, Text, StyleSheet, Pressable} from 'react-native';

/**
 * Card Component
 * Reusable card container with shadow
 */

interface CardProps {
  children: React.ReactNode;
  onPress?: () => void;
  style?: any;
}

export default function Card({children, onPress, style}: CardProps) {
  const Container = onPress ? Pressable : View;

  return (
    <Container
      style={({pressed}: any) => [
        styles.card,
        style,
        onPress && pressed && styles.pressed,
      ]}
      onPress={onPress}>
      {children}
    </Container>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  pressed: {
    opacity: 0.8,
  },
});
