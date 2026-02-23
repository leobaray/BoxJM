import React, { useState, useMemo, useCallback } from 'react';
import {
  View, Text, SectionList, StyleSheet, TouchableOpacity,
  ActivityIndicator, TextInput, ScrollView
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useBudgets } from '@/hooks/useBudgets';
import { BudgetCard } from '@/components/ui/BudgetCard';
import { useRouter } from 'expo-router';
import { Budget } from '@/types/budget';

/* ─── Constants ─────────────────────────────────────────────────────────── */

const STATUS_FILTERS = [
  { key: null,        label: 'Todos',    color: '#ef4444' },
  { key: 'draft',     label: 'Rascunho', color: '#6b7280' },
  { key: 'sent',      label: 'Enviado',  color: '#3b82f6' },
  { key: 'approved',  label: 'Aprovado', color: '#10b981' },
  { key: 'completed', label: 'Concluído',color: '#8b5cf6' },
] as const;

type SortOption = 'recent' | 'value' | 'status';

const SORT_LABELS: Record<SortOption, string> = {
  recent: 'Mais recente',
  value:  'Maior valor',
  status: 'Status',
};

const SORT_OPTIONS: SortOption[] = ['recent', 'value', 'status'];

/* ─── Helpers ───────────────────────────────────────────────────────────── */

function getDateGroup(dateStr: string): string {
  const today     = new Date(); today.setHours(0, 0, 0, 0);
  const yesterday = new Date(today); yesterday.setDate(yesterday.getDate() - 1);
  const weekAgo   = new Date(today); weekAgo.setDate(weekAgo.getDate() - 7);

  const d = new Date(dateStr); d.setHours(0, 0, 0, 0);
  const t = d.getTime();

  if (t === today.getTime())          return 'Hoje';
  if (t === yesterday.getTime())      return 'Ontem';
  if (t >= weekAgo.getTime())         return 'Esta semana';
  return 'Mais antigos';
}

const DATE_GROUP_ORDER = ['Hoje', 'Ontem', 'Esta semana', 'Mais antigos'];

/* ─── Component ─────────────────────────────────────────────────────────── */

export default function HomeScreen() {
  const insets = useSafeAreaInsets();
  const { budgets, loading, refreshBudgets } = useBudgets();
  const router = useRouter();

  const [search,       setSearch]       = useState('');
  const [activeStatus, setActiveStatus] = useState<string | null>(null);
  const [sortOrder,    setSortOrder]    = useState<SortOption>('recent');
  const [refreshing,   setRefreshing]   = useState(false);

  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    await refreshBudgets();
    setRefreshing(false);
  }, [refreshBudgets]);

  const cycleSortOrder = () => {
    setSortOrder(prev => {
      const idx = SORT_OPTIONS.indexOf(prev);
      return SORT_OPTIONS[(idx + 1) % SORT_OPTIONS.length];
    });
  };

  /* Filter → Sort → Section */
  const processedBudgets = useMemo(() => {
    const q = search.trim().toLowerCase();
    const filtered = budgets.filter(b => {
      const matchSearch = !q ||
        b.clientName.toLowerCase().includes(q) ||
        `${b.vehicleBrand} ${b.vehicleModel}`.toLowerCase().includes(q);
      const matchStatus = !activeStatus || b.status === activeStatus;
      return matchSearch && matchStatus;
    });

    return [...filtered].sort((a, b) => {
      switch (sortOrder) {
        case 'recent': return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
        case 'value':  return b.total - a.total;
        case 'status': {
          const order = { draft: 0, sent: 1, approved: 2, completed: 3 };
          return order[a.status] - order[b.status];
        }
      }
    });
  }, [budgets, search, activeStatus, sortOrder]);

  const sections = useMemo(() => {
    // Agrupamento por data só faz sentido quando ordenado por data
    if (sortOrder !== 'recent') {
      return [{ title: null as string | null, data: processedBudgets }];
    }

    const groups: Record<string, Budget[]> = {};
    processedBudgets.forEach(b => {
      const group = getDateGroup(b.createdAt);
      if (!groups[group]) groups[group] = [];
      groups[group].push(b);
    });

    return DATE_GROUP_ORDER
      .filter(g => groups[g]?.length)
      .map(g => ({ title: g as string | null, data: groups[g] }));
  }, [processedBudgets, sortOrder]);

  /* ── Loading ── */
  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color="#ef4444" />
      </View>
    );
  }

  const isFiltered   = !!search.trim() || !!activeStatus;
  const noResults    = budgets.length > 0 && processedBudgets.length === 0;
  const counterLabel = isFiltered && processedBudgets.length !== budgets.length
    ? `${processedBudgets.length} de ${budgets.length}`
    : `${budgets.length} ${budgets.length === 1 ? 'orçamento' : 'orçamentos'}`;

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>

      {/* ── Header ── */}
      <View style={styles.header}>
        <View>
          <Text style={styles.brandName}>BOX JM</Text>
          <Text style={styles.title}>Orçamentos</Text>
          <Text style={styles.subtitle}>Gerencie seus trabalhos</Text>
        </View>
        <TouchableOpacity style={styles.refreshButton} onPress={handleRefresh}>
          <MaterialCommunityIcons name="refresh" size={22} color="#ef4444" />
        </TouchableOpacity>
      </View>

      {/* ── Search + Filters ── */}
      {budgets.length > 0 && (
        <View style={styles.searchSection}>
          <View style={styles.searchInputWrapper}>
            <MaterialCommunityIcons name="magnify" size={19} color="#6b7280" />
            <TextInput
              style={styles.searchInput}
              placeholder="Buscar cliente ou veículo..."
              placeholderTextColor="#6b7280"
              value={search}
              onChangeText={setSearch}
            />
            {search.length > 0 && (
              <TouchableOpacity
                onPress={() => setSearch('')}
                hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
              >
                <MaterialCommunityIcons name="close-circle" size={17} color="#6b7280" />
              </TouchableOpacity>
            )}
          </View>

          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.filtersRow}
          >
            {STATUS_FILTERS.map(filter => {
              const isActive = activeStatus === filter.key;
              return (
                <TouchableOpacity
                  key={String(filter.key)}
                  style={[styles.filterPill, isActive && { backgroundColor: filter.color, borderColor: filter.color }]}
                  onPress={() => setActiveStatus(isActive ? null : filter.key)}
                  activeOpacity={0.7}
                >
                  <Text style={[styles.filterPillText, isActive && styles.filterPillTextActive]}>
                    {filter.label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </ScrollView>
        </View>
      )}

      {/* ── Sort + Counter ── */}
      {budgets.length > 0 && (
        <View style={styles.controlsRow}>
          <TouchableOpacity style={styles.sortButton} onPress={cycleSortOrder} activeOpacity={0.7}>
            <MaterialCommunityIcons name="sort-variant" size={15} color="#9ca3af" />
            <Text style={styles.sortText}>{SORT_LABELS[sortOrder]}</Text>
          </TouchableOpacity>
          <Text style={styles.countText}>{counterLabel}</Text>
        </View>
      )}

      {/* ── Empty (sem nenhum orçamento) ── */}
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

      /* ── Sem resultado de filtro ── */
      ) : noResults ? (
        <View style={styles.emptyState}>
          <MaterialCommunityIcons name="magnify-close" size={64} color="#374151" />
          <Text style={styles.emptyTitle}>Nenhum resultado</Text>
          <Text style={styles.emptyText}>
            {search.trim()
              ? `Nenhum orçamento para "${search.trim()}"`
              : 'Nenhum orçamento com este status'}
          </Text>
          <TouchableOpacity
            style={styles.clearButton}
            onPress={() => { setSearch(''); setActiveStatus(null); }}
          >
            <Text style={styles.clearButtonText}>Limpar filtros</Text>
          </TouchableOpacity>
        </View>

      /* ── Lista com seções ── */
      ) : (
        <SectionList
          sections={sections}
          keyExtractor={item => item.id}
          renderItem={({ item }) => <BudgetCard budget={item} />}
          renderSectionHeader={({ section }) => {
            if (!section.title) return null;
            return (
              <View style={styles.dateHeader}>
                <Text style={styles.dateHeaderText}>{section.title}</Text>
                <View style={styles.dateHeaderLine} />
              </View>
            );
          }}
          contentContainerStyle={styles.listContent}
          showsVerticalScrollIndicator={false}
          onRefresh={handleRefresh}
          refreshing={refreshing}
          stickySectionHeadersEnabled={false}
        />
      )}
    </View>
  );
}

/* ─── Styles ─────────────────────────────────────────────────────────────── */

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

  /* Header */
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

  /* Search + Filters */
  searchSection: {
    paddingTop: 12,
    paddingBottom: 4,
    borderBottomWidth: 1,
    borderBottomColor: '#1f1f1f'
  },
  searchInputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1f1f1f',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#2f2f2f',
    paddingHorizontal: 14,
    marginHorizontal: 20,
    marginBottom: 10,
    gap: 8,
    height: 44
  },
  searchInput: {
    flex: 1,
    fontSize: 15,
    color: '#ffffff'
  },
  filtersRow: {
    paddingHorizontal: 20,
    gap: 8,
    paddingBottom: 12
  },
  filterPill: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#2f2f2f',
    backgroundColor: '#1f1f1f'
  },
  filterPillText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#6b7280'
  },
  filterPillTextActive: {
    color: '#ffffff'
  },

  /* Sort + Counter */
  controlsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#1f1f1f'
  },
  sortButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5
  },
  sortText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#9ca3af'
  },
  countText: {
    fontSize: 13,
    fontWeight: '500',
    color: '#4b5563'
  },

  /* List */
  listContent: {
    padding: 20
  },

  /* Date section headers */
  dateHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 12,
    marginTop: 4
  },
  dateHeaderText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#6b7280',
    textTransform: 'uppercase',
    letterSpacing: 0.8
  },
  dateHeaderLine: {
    flex: 1,
    height: 1,
    backgroundColor: '#1f1f1f'
  },

  /* Empty / No Results */
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
  },
  clearButton: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#2f2f2f'
  },
  clearButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#9ca3af'
  }
});
