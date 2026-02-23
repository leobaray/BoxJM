import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, Alert, Share, TextInput, Modal } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { useBudgets } from '@/hooks/useBudgets';
import { Budget } from '@/types/budget';
import { STATUS_LABELS, VEHICLE_MULTIPLIERS } from '@/constants/services';

export default function BudgetDetailScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { id } = useLocalSearchParams();
  const { budgets, updateBudget, deleteBudget } = useBudgets();
  const [budget, setBudget]                   = useState<Budget | null>(null);
  const [showEditTotalModal, setShowEditTotalModal] = useState(false);
  const [newTotalInput, setNewTotalInput]     = useState('');
  const [deleting, setDeleting]               = useState(false);
  const [savingTotal, setSavingTotal]         = useState(false);

  useEffect(() => {
    const found = budgets.find(b => b.id === id);
    setBudget(found || null);
  }, [id, budgets]);

  const handleStatusChange = async (newStatus: Budget['status']) => {
    if (!budget) return;
    try {
      await updateBudget(budget.id, { status: newStatus });
      Alert.alert('Sucesso', 'Status atualizado');
    } catch {
      Alert.alert('Erro', 'Não foi possível atualizar o status');
    }
  };

  const handleEdit = () => {
    if (!budget) return;
    router.push({ pathname: '/(tabs)/new-budget', params: { id: budget.id } });
  };

  const handleDelete = () => {
    if (!budget) {
      Alert.alert('Erro', 'Orçamento não encontrado');
      return;
    }
    Alert.alert(
      'Excluir orçamento',
      'Tem certeza que deseja excluir este orçamento? Esta ação não pode ser desfeita.',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Excluir',
          style: 'destructive',
          onPress: async () => {
            setDeleting(true);
            try {
              await deleteBudget(budget.id);
              Alert.alert('Sucesso', 'Orçamento excluído', [{ text: 'OK', onPress: () => router.back() }]);
            } catch (error) {
              const message = error instanceof Error ? error.message : 'Tente novamente';
              Alert.alert('Erro', `Não foi possível excluir o orçamento. ${message}`);
            } finally {
              setDeleting(false);
            }
          }
        }
      ]
    );
  };

  const handleEditTotal = () => {
    if (!budget) return;
    setNewTotalInput(budget.total.toFixed(2));
    setShowEditTotalModal(true);
  };

  const handleSaveNewTotal = async () => {
    if (!budget || savingTotal) return;
    const newTotal = parseFloat(newTotalInput.replace(',', '.'));
    if (isNaN(newTotal) || newTotal <= 0) {
      Alert.alert('Erro', 'Digite um valor válido maior que zero');
      return;
    }
    if (budget.total === 0 || budget.items.length === 0) {
      Alert.alert('Erro', 'Não é possível ajustar um orçamento sem valor ou sem serviços');
      return;
    }
    setSavingTotal(true);
    try {
      const adjustmentFactor = newTotal / budget.total;
      const adjustedItems    = budget.items.map(item => ({
        ...item,
        basePrice: Math.round(item.basePrice * adjustmentFactor * 100) / 100
      }));
      const newSubtotal = adjustedItems.reduce((sum, item) => sum + (item.basePrice * item.quantity), 0);
      await updateBudget(budget.id, {
        items:    adjustedItems,
        subtotal: Math.round(newSubtotal * 100) / 100,
        total:    Math.round(newTotal * 100) / 100
      });
      setShowEditTotalModal(false);
      Alert.alert('Sucesso', 'Valor total atualizado e serviços ajustados proporcionalmente');
    } catch {
      Alert.alert('Erro', 'Não foi possível atualizar o valor');
    } finally {
      setSavingTotal(false);
    }
  };

  const handleShare = async () => {
    if (!budget) return;
    if (!budget.clientName || !budget.vehicleBrand || !budget.vehicleModel) {
      Alert.alert('Erro', 'Dados do orçamento incompletos. Não é possível compartilhar.');
      return;
    }
    if (!budget.items || budget.items.length === 0) {
      Alert.alert('Erro', 'Orçamento sem serviços. Adicione serviços antes de compartilhar.');
      return;
    }
    try {
      const message = `
━━━━━━━━━━━━━━━━━━━━━━
    BOX JM
    Estética Automotiva
━━━━━━━━━━━━━━━━━━━━━━

📋 ORÇAMENTO

👤 Cliente: ${budget.clientName}
${budget.clientPhone ? `📞 ${budget.clientPhone}\n` : ''}
🚗 Veículo: ${budget.vehicleBrand} ${budget.vehicleModel}

━━━━━━━━━━━━━━━━━━━━━━
SERVIÇOS:

${budget.items.map((item, index) =>
  `${index + 1}. ${item.serviceName}
   R$ ${item.basePrice.toFixed(2).replace('.', ',')} x ${item.quantity} = R$ ${(item.basePrice * item.quantity).toFixed(2).replace('.', ',')}`
).join('\n\n')}

━━━━━━━━━━━━━━━━━━━━━━
${budget.notes ? `\n💬 Observações:\n${budget.notes}\n\n━━━━━━━━━━━━━━━━━━━━━━\n` : ''}
💰 VALOR TOTAL: R$ ${budget.total.toFixed(2).replace('.', ',')}

━━━━━━━━━━━━━━━━━━━━━━

Obrigado pela preferência! 🚗✨
━━━━━━━━━━━━━━━━━━━━━━
      `.trim();
      await Share.share({ message, title: `Orçamento - ${budget.clientName}` });
    } catch {
      Alert.alert('Erro', 'Não foi possível compartilhar o orçamento');
    }
  };

  if (!budget) {
    return (
      <View style={[styles.container, { paddingTop: insets.top }]}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
            <MaterialCommunityIcons name="arrow-left" size={24} color="#ffffff" />
          </TouchableOpacity>
          <Text style={styles.title}>Carregando...</Text>
        </View>
      </View>
    );
  }

  const STATUS_COLORS: Record<Budget['status'], string> = {
    draft:     '#6b7280',
    sent:      '#3b82f6',
    approved:  '#10b981',
    completed: '#8b5cf6'
  };

  const vehicleLabel = VEHICLE_MULTIPLIERS.find(v => v.type === budget.vehicleType)?.label ?? budget.vehicleType;

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <MaterialCommunityIcons name="arrow-left" size={24} color="#ffffff" />
        </TouchableOpacity>
        <View style={styles.headerCenter}>
          <Text style={styles.brandName}>BOX JM</Text>
          <Text style={styles.title}>Detalhes</Text>
        </View>
        <View style={styles.headerRight}>
          <TouchableOpacity onPress={handleShare} style={styles.headerButton}>
            <MaterialCommunityIcons name="share-variant" size={20} color="#10b981" />
          </TouchableOpacity>
          <TouchableOpacity onPress={handleEdit} style={styles.headerButton}>
            <MaterialCommunityIcons name="pencil" size={20} color="#3b82f6" />
          </TouchableOpacity>
          <TouchableOpacity onPress={handleDelete} style={styles.headerButton} disabled={deleting}>
            <MaterialCommunityIcons name="delete" size={20} color={deleting ? '#6b7280' : '#ef4444'} />
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>

        {/* Cliente */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>Cliente</Text>
            <View style={[styles.statusBadge, { backgroundColor: STATUS_COLORS[budget.status] }]}>
              <Text style={styles.statusText}>{STATUS_LABELS[budget.status]}</Text>
            </View>
          </View>
          <Text style={styles.clientName}>{budget.clientName}</Text>
          {budget.clientPhone && (
            <View style={styles.infoRow}>
              <MaterialCommunityIcons name="phone" size={15} color="#6b7280" />
              <Text style={styles.infoText}>{budget.clientPhone}</Text>
            </View>
          )}
        </View>

        {/* Veículo */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Veículo</Text>
          <Text style={styles.vehicleName}>{budget.vehicleBrand} {budget.vehicleModel}</Text>
          <View style={styles.infoRow}>
            <MaterialCommunityIcons name="car" size={15} color="#6b7280" />
            <Text style={styles.infoText}>Tipo: {vehicleLabel}</Text>
          </View>
          <View style={styles.infoRow}>
            <MaterialCommunityIcons name="calculator" size={15} color="#6b7280" />
            <Text style={styles.infoText}>Multiplicador: x{budget.multiplier.toFixed(1)}</Text>
          </View>
        </View>

        {/* Serviços */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Serviços</Text>
          {budget.items.map((item, index) => (
            <View
              key={index}
              style={[
                styles.serviceRow,
                index === budget.items.length - 1 && styles.serviceRowLast
              ]}
            >
              <View style={styles.serviceInfo}>
                <Text style={styles.serviceName}>{item.serviceName}</Text>
                <Text style={styles.serviceDetail}>
                  R$ {item.basePrice.toFixed(2).replace('.', ',')} × {item.quantity}
                </Text>
              </View>
              <Text style={styles.serviceTotal}>
                R$ {(item.basePrice * item.quantity).toFixed(2).replace('.', ',')}
              </Text>
            </View>
          ))}
        </View>

        {/* Observações */}
        {budget.notes && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Observações</Text>
            <Text style={styles.notesText}>{budget.notes}</Text>
          </View>
        )}

        {/* Totais */}
        <View style={styles.totalsCard}>
          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>Subtotal</Text>
            <Text style={styles.totalValue}>R$ {budget.subtotal.toFixed(2).replace('.', ',')}</Text>
          </View>
          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>Multiplicador</Text>
            <Text style={styles.totalValue}>x{budget.multiplier.toFixed(1)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.totalRow}>
            <Text style={styles.finalLabel}>Total</Text>
            <View style={styles.totalValueContainer}>
              <Text style={styles.finalValue}>R$ {budget.total.toFixed(2).replace('.', ',')}</Text>
              <TouchableOpacity onPress={handleEditTotal} style={styles.editTotalButton}>
                <MaterialCommunityIcons name="pencil" size={16} color="#3b82f6" />
              </TouchableOpacity>
            </View>
          </View>
        </View>

        {/* Atualizar Status */}
        <View style={styles.actionsCard}>
          <Text style={styles.cardTitle}>Atualizar Status</Text>
          <View style={styles.statusButtons}>
            {(['sent', 'approved', 'completed'] as const).map((status) => {
              const isActive = budget.status === status;
              return (
                <TouchableOpacity
                  key={status}
                  style={[
                    styles.statusButton,
                    isActive && { backgroundColor: STATUS_COLORS[status] }
                  ]}
                  onPress={() => handleStatusChange(status)}
                  activeOpacity={0.7}
                >
                  {isActive && (
                    <MaterialCommunityIcons name="check-circle" size={16} color="#ffffff" />
                  )}
                  <Text style={[styles.statusButtonText, isActive && styles.statusButtonTextActive]}>
                    {STATUS_LABELS[status]}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        {/* Metadata */}
        <View style={styles.metadata}>
          <Text style={styles.metadataText}>
            Criado em {new Date(budget.createdAt).toLocaleString('pt-BR')}
          </Text>
        </View>

      </ScrollView>

      {/* Modal Editar Total */}
      <Modal
        visible={showEditTotalModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowEditTotalModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Editar Valor Total</Text>
              <TouchableOpacity onPress={() => setShowEditTotalModal(false)}>
                <MaterialCommunityIcons name="close" size={22} color="#6b7280" />
              </TouchableOpacity>
            </View>

            <Text style={styles.modalDescription}>
              Os valores dos serviços serão ajustados proporcionalmente ao novo total.
            </Text>

            <View style={styles.inputContainer}>
              <Text style={styles.inputLabel}>Novo Valor Total</Text>
              <View style={styles.currencyInputWrapper}>
                <Text style={styles.currencySymbol}>R$</Text>
                <TextInput
                  style={styles.currencyInput}
                  value={newTotalInput}
                  onChangeText={setNewTotalInput}
                  keyboardType="decimal-pad"
                  placeholder="0,00"
                  placeholderTextColor="#6b7280"
                  autoFocus
                />
              </View>
            </View>

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.cancelButton]}
                onPress={() => setShowEditTotalModal(false)}
              >
                <Text style={styles.cancelButtonText}>Cancelar</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, styles.saveButton, savingTotal && { opacity: 0.6 }]}
                onPress={handleSaveNewTotal}
                disabled={savingTotal}
              >
                <Text style={styles.saveButtonText}>{savingTotal ? 'Salvando...' : 'Salvar'}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a'
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#1f1f1f'
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#1f1f1f',
    justifyContent: 'center',
    alignItems: 'center'
  },
  headerCenter: {
    flex: 1,
    alignItems: 'center'
  },
  headerRight: {
    flexDirection: 'row',
    gap: 6
  },
  headerButton: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#1f1f1f',
    justifyContent: 'center',
    alignItems: 'center'
  },
  brandName: {
    fontSize: 12,
    fontWeight: '900',
    color: '#ef4444',
    letterSpacing: 2,
    marginBottom: 2
  },
  title: {
    fontSize: 22,
    fontWeight: '800',
    color: '#ffffff'
  },
  content: {
    padding: 20,
    paddingBottom: 40
  },

  /* Cards */
  card: {
    backgroundColor: '#1f1f1f',
    borderRadius: 16,
    padding: 16,
    marginBottom: 12
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12
  },
  cardTitle: {
    fontSize: 11,
    fontWeight: '700',
    color: '#6b7280',
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 0.8
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
  clientName: {
    fontSize: 20,
    fontWeight: '700',
    color: '#ffffff',
    marginBottom: 8
  },
  vehicleName: {
    fontSize: 18,
    fontWeight: '700',
    color: '#ffffff',
    marginBottom: 10
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 4
  },
  infoText: {
    fontSize: 14,
    color: '#9ca3af'
  },

  /* Services list */
  serviceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#2f2f2f'
  },
  serviceRowLast: {
    borderBottomWidth: 0,
    paddingBottom: 0
  },
  serviceInfo: {
    flex: 1
  },
  serviceName: {
    fontSize: 15,
    fontWeight: '600',
    color: '#ffffff',
    marginBottom: 3
  },
  serviceDetail: {
    fontSize: 13,
    color: '#6b7280'
  },
  serviceTotal: {
    fontSize: 15,
    fontWeight: '700',
    color: '#ef4444',
    marginLeft: 12
  },
  notesText: {
    fontSize: 14,
    color: '#d1d5db',
    lineHeight: 22
  },

  /* Totals card */
  totalsCard: {
    backgroundColor: '#1f1f1f',
    borderRadius: 16,
    padding: 20,
    marginBottom: 12,
    borderWidth: 2,
    borderColor: '#ef4444'
  },
  totalRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8
  },
  totalLabel: {
    fontSize: 14,
    color: '#9ca3af'
  },
  totalValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#ffffff'
  },
  divider: {
    height: 1,
    backgroundColor: '#2f2f2f',
    marginVertical: 12
  },
  finalLabel: {
    fontSize: 18,
    fontWeight: '700',
    color: '#ffffff'
  },
  finalValue: {
    fontSize: 28,
    fontWeight: '800',
    color: '#ef4444'
  },
  totalValueContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10
  },
  editTotalButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#1f2937',
    justifyContent: 'center',
    alignItems: 'center'
  },

  /* Actions card */
  actionsCard: {
    backgroundColor: '#1f1f1f',
    borderRadius: 16,
    padding: 16,
    marginBottom: 12
  },
  statusButtons: {
    gap: 8
  },
  statusButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: '#2a2a2a',
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#2f2f2f'
  },
  statusButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#9ca3af'
  },
  statusButtonTextActive: {
    color: '#ffffff'
  },

  /* Metadata */
  metadata: {
    alignItems: 'center',
    paddingVertical: 12
  },
  metadataText: {
    fontSize: 12,
    color: '#4b5563'
  },

  /* Modal */
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.85)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20
  },
  modalContent: {
    backgroundColor: '#1f1f1f',
    borderRadius: 20,
    padding: 24,
    width: '100%',
    maxWidth: 400,
    borderWidth: 1,
    borderColor: '#2f2f2f'
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#ffffff'
  },
  modalDescription: {
    fontSize: 14,
    color: '#9ca3af',
    marginBottom: 20,
    lineHeight: 20
  },
  inputContainer: {
    marginBottom: 24
  },
  inputLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: '#9ca3af',
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 0.5
  },
  currencyInputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#0a0a0a',
    borderRadius: 12,
    borderWidth: 2,
    borderColor: '#ef4444',
    paddingHorizontal: 16
  },
  currencySymbol: {
    fontSize: 22,
    fontWeight: '700',
    color: '#ef4444',
    marginRight: 8
  },
  currencyInput: {
    flex: 1,
    fontSize: 24,
    fontWeight: '700',
    color: '#ffffff',
    paddingVertical: 16
  },
  modalButtons: {
    flexDirection: 'row',
    gap: 12
  },
  modalButton: {
    flex: 1,
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center'
  },
  cancelButton: {
    backgroundColor: '#2a2a2a',
    borderWidth: 1,
    borderColor: '#2f2f2f'
  },
  cancelButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#9ca3af'
  },
  saveButton: {
    backgroundColor: '#ef4444'
  },
  saveButtonText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#ffffff'
  }
});
