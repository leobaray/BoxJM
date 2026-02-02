import React from 'react';
import { View, Text, FlatList, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useBudgets } from '@/hooks/useBudgets';
import { BudgetCard } from '@/components/ui/BudgetCard';
import { useRouter } from 'expo-router';

export default function HomeScreen() {
  const insets = useSafeAreaInsets();
  const { budgets, loading, refreshBudgets } = useBudgets();
  const router = useRouter();

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color="#ef4444" />
      </View>
    );
  }

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <View style={styles.header}>
        <View>
          <Text style={styles.brandName}>BOX JM</Text>
          <Text style={styles.title}>Orçamentos</Text>
          <Text style={styles.subtitle}>Gerencie seus trabalhos</Text>
        </View>
        <TouchableOpacity
          style={styles.refreshButton}
          onPress={refreshBudgets}
        >
          <MaterialCommunityIcons name="refresh" size={24} color="#ef4444" />
        </TouchableOpacity>
      </View>

      {budgets.length === 0 ? (
        <View style={styles.emptyState}>
          <MaterialCommunityIcons name="file-document-outline" size={80} color="#374151" />
          <Text style={styles.emptyTitle}>Nenhum orçamento ainda</Text>
          <Text style={styles.emptyText}>Crie seu primeiro orçamento na aba "Novo"</Text>
          <TouchableOpacity
            style={styles.createButton}
            onPress={() => router.push('/(tabs)/new-budget')}
          >
            <MaterialCommunityIcons name="plus" size={20} color="#ffffff" />
            <Text style={styles.createButtonText}>Criar Orçamento</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <FlatList
          data={budgets}
          keyExtractor={item => item.id}
          renderItem={({ item }) => <BudgetCard budget={item} />}
          contentContainerStyle={styles.listContent}
          showsVerticalScrollIndicator={false}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a'
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#0a0a0a'
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#1f1f1f'
  },
  brandName: {
    fontSize: 14,
    fontWeight: '900',
    color: '#ef4444',
    letterSpacing: 2,
    marginBottom: 4
  },
  title: {
    fontSize: 28,
    fontWeight: '800',
    color: '#ffffff'
  },
  subtitle: {
    fontSize: 14,
    color: '#9ca3af',
    marginTop: 2
  },
  refreshButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#1f1f1f',
    justifyContent: 'center',
    alignItems: 'center'
  },
  listContent: {
    padding: 20
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#ffffff',
    marginTop: 16,
    marginBottom: 8
  },
  emptyText: {
    fontSize: 14,
    color: '#9ca3af',
    textAlign: 'center',
    marginBottom: 24
  },
  createButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: '#ef4444',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12
  },
  createButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#ffffff'
  }
});