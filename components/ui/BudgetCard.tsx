import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Budget } from '@/types/budget';
import { STATUS_LABELS } from '@/constants/services';
import { useRouter } from 'expo-router';

interface BudgetCardProps {
  budget: Budget;
}

export const BudgetCard = React.memo(({ budget }: BudgetCardProps) => {
  const router = useRouter();

  const statusColors = {
    draft: '#6b7280',
    sent: '#3b82f6',
    approved: '#10b981',
    completed: '#8b5cf6'
  };

  // Fallbacks para dados que podem estar ausentes
  const clientName = budget.clientName || 'Cliente sem nome';
  const vehicleBrand = budget.vehicleBrand || 'Marca';
  const vehicleModel = budget.vehicleModel || 'Modelo';
  const itemCount = budget.items?.length || 0;

  return (
    <TouchableOpacity
      style={styles.card}
      onPress={() => router.push(`/budget/${budget.id}`)}
      activeOpacity={0.7}
    >
      <View style={styles.header}>
        <View style={styles.clientInfo}>
          <Text style={styles.clientName}>{clientName}</Text>
          <Text style={styles.vehicleInfo}>
            {vehicleBrand} {vehicleModel}
          </Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: statusColors[budget.status] }]}>
          <Text style={styles.statusText}>{STATUS_LABELS[budget.status]}</Text>
        </View>
      </View>

      <View style={styles.divider} />

      <View style={styles.details}>
        <View style={styles.detailRow}>
          <MaterialCommunityIcons name="car-wash" size={18} color="#ef4444" />
          <Text style={styles.detailText}>{itemCount} serviços</Text>
        </View>
        <View style={styles.detailRow}>
          <MaterialCommunityIcons name="calendar" size={18} color="#ef4444" />
          <Text style={styles.detailText}>
            {new Date(budget.createdAt).toLocaleDateString('pt-BR')}
          </Text>
        </View>
      </View>

      <View style={styles.footer}>
        <View>
          <Text style={styles.totalLabel}>Total</Text>
          <Text style={styles.totalValue}>
            R$ {budget.total.toFixed(2).replace('.', ',')}
          </Text>
        </View>
        <MaterialCommunityIcons name="chevron-right" size={24} color="#ef4444" />
      </View>
    </TouchableOpacity>
  );
});

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#1f1f1f',
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#2f2f2f',
    shadowColor: '#ef4444',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12
  },
  clientInfo: {
    flex: 1
  },
  clientName: {
    fontSize: 18,
    fontWeight: '700',
    color: '#ffffff',
    marginBottom: 4
  },
  vehicleInfo: {
    fontSize: 14,
    color: '#9ca3af'
  },
  statusBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12
  },
  statusText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#ffffff'
  },
  divider: {
    height: 1,
    backgroundColor: '#2f2f2f',
    marginBottom: 12
  },
  details: {
    flexDirection: 'row',
    gap: 16,
    marginBottom: 12
  },
  detailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6
  },
  detailText: {
    fontSize: 13,
    color: '#9ca3af'
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#2f2f2f'
  },
  totalLabel: {
    fontSize: 12,
    color: '#9ca3af',
    marginBottom: 2
  },
  totalValue: {
    fontSize: 24,
    fontWeight: '800',
    color: '#ef4444'
  }
});