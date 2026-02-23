import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';

export default function NotFoundScreen() {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.container, { paddingTop: insets.top, paddingBottom: insets.bottom }]}>
      <View style={styles.content}>
        <View style={styles.iconWrapper}>
          <MaterialCommunityIcons name="file-search-outline" size={52} color="#ef4444" />
        </View>
        <Text style={styles.brand}>BOX JM</Text>
        <Text style={styles.title}>Página não encontrada</Text>
        <Text style={styles.message}>
          Esta rota não existe ou foi removida.
        </Text>
        <TouchableOpacity
          style={styles.homeButton}
          onPress={() => router.push('/')}
          activeOpacity={0.8}
        >
          <MaterialCommunityIcons name="arrow-left" size={18} color="#ffffff" />
          <Text style={styles.homeButtonText}>Voltar ao início</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a'
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40
  },
  iconWrapper: {
    width: 88,
    height: 88,
    borderRadius: 44,
    backgroundColor: '#1f1f1f',
    borderWidth: 1,
    borderColor: '#2f2f2f',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 24
  },
  brand: {
    fontSize: 13,
    fontWeight: '900',
    color: '#ef4444',
    letterSpacing: 2,
    marginBottom: 8
  },
  title: {
    fontSize: 22,
    fontWeight: '800',
    color: '#ffffff',
    marginBottom: 10
  },
  message: {
    fontSize: 14,
    color: '#9ca3af',
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: 32
  },
  homeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: '#ef4444',
    paddingHorizontal: 24,
    paddingVertical: 13,
    borderRadius: 12
  },
  homeButtonText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#ffffff'
  }
});
