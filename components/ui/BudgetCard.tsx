import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Budget } from '@/types/budget';
import { STATUS_LABELS } from '@/constants/services';
import { useRouter } from 'expo-router';

interface BudgetCardProps {
  budget: Budget;
}

const STATUS_COLORS: Record<Budget['status'], string> = {
  draft:     '#6b7280',
  sent:      '#3b82f6',
  approved:  '#10b981',
  completed: '#8b5cf6'
};

export const BudgetCard = React.memo(({ budget }: BudgetCardProps) => {
  const router = useRouter();

  const clientName  = budget.clientName  || 'Cliente sem nome';
  const vehicleBrand = budget.vehicleBrand || 'Marca';
  const vehicleModel = budget.vehicleModel || 'Modelo';
  const itemCount   = budget.items?.length || 0;
  const statusColor = STATUS_COLORS[budget.status];

  return (
    <TouchableOpacity
      style={[styles.card, { borderLeftColor: statusColor }]}
      onPress={() => router.push(`/budget/${budget.id}`)}
      activeOpacity={0.7}
    >
      <View style={styles.header}>
        <View style={styles.clientInfo}>
          <Text style={styles.clientName}>{clientName}</Text>
          <Text style={styles.vehicleInfo}>{vehicleBrand} {vehicleModel}</Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: statusColor }]}>
          <Text style={styles.statusText}>{STATUS_LABELS[budget.status]}</Text>
        </View>
      </View>

      <View style={styles.divider} />

      <View style={styles.details}>
        <View style={styles.detailRow}>
          <MaterialCommunityIcons name="car-wash" size={16} color="#6b7280" />
          <Text style={styles.detailText}>{itemCount} {itemCount === 1 ? 'serviço' : 'serviços'}</Text>
        </View>
        <View style={styles.detailRow}>
          <MaterialCommunityIcons name="calendar" size={16} color="#6b7280" />
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
        <MaterialCommunityIcons name="chevron-right" size={22} color="#374151" />
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
    borderLeftWidth: 3,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 6,
    elevation: 3
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12
  },
  clientInfo: {
    flex: 1,
    paddingRight: 12
  },
  clientName: {
    fontSize: 17,
    fontWeight: '700',
    color: '#ffffff',
    marginBottom: 3
  },
  vehicleInfo: {
    fontSize: 13,
    color: '#9ca3af'
  },
  statusBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 20
  },
  statusText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#ffffff',
    letterSpacing: 0.3
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
    gap: 5
  },
  detailText: {
    fontSize: 13,
    color: '#6b7280'
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
    fontSize: 11,
    fontWeight: '600',
    color: '#6b7280',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: 2
  },
  totalValue: {
    fontSize: 22,
    fontWeight: '800',
    color: '#ef4444'
  }
});
