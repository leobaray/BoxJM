import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, Alert, Share, TextInput, Modal } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { useBudgets } from '@/hooks/useBudgets';
import { Budget } from '@/types/budget';
import { STATUS_LABELS } from '@/constants/services';

export default function BudgetDetailScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { id } = useLocalSearchParams();
  const { budgets, updateBudget, deleteBudget } = useBudgets();
  const [budget, setBudget] = useState<Budget | null>(null);
  const [showEditTotalModal, setShowEditTotalModal] = useState(false);
  const [newTotalInput, setNewTotalInput] = useState('');

  useEffect(() => {
    const found = budgets.find(b => b.id === id);
    setBudget(found || null);
  }, [id, budgets]);

  const handleStatusChange = async (newStatus: Budget['status']) => {
    if (!budget) return;
    try {
      await updateBudget(budget.id, { status: newStatus });
      Alert.alert('Sucesso', 'Status atualizado');
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível atualizar o status');
    }
  };

  const handleEdit = () => {
    if (!budget) return;
    router.push({
      pathname: '/(tabs)/new-budget',
      params: { id: budget.id }
    });
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
            try {
              console.log('Deletando orçamento:', budget.id);
              await deleteBudget(budget.id);
              console.log('Orçamento deletado com sucesso');
              Alert.alert('Sucesso', 'Orçamento excluído', [
                { text: 'OK', onPress: () => router.back() }
              ]);
            } catch (error) {
              console.error('Erro ao deletar orçamento:', error);
              Alert.alert('Erro', `Não foi possível excluir o orçamento: ${error}`);
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
    if (!budget) return;
    
    const newTotal = parseFloat(newTotalInput.replace(',', '.'));
    
    if (isNaN(newTotal) || newTotal <= 0) {
      Alert.alert('Erro', 'Digite um valor válido maior que zero');
      return;
    }

    try {
      // Calcular fator de ajuste
      const adjustmentFactor = newTotal / budget.total;
      
      // Ajustar preços dos serviços proporcionalmente
      const adjustedItems = budget.items.map(item => ({
        ...item,
        basePrice: Math.round(item.basePrice * adjustmentFactor * 100) / 100
      }));
      
      // Recalcular subtotal
      const newSubtotal = adjustedItems.reduce((sum, item) => 
        sum + (item.basePrice * item.quantity), 0
      );
      
      // Atualizar orçamento
      await updateBudget(budget.id, {
        items: adjustedItems,
        subtotal: Math.round(newSubtotal * 100) / 100,
        total: Math.round(newTotal * 100) / 100
      });
      
      setShowEditTotalModal(false);
      Alert.alert('Sucesso', 'Valor total atualizado e serviços ajustados proporcionalmente');
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível atualizar o valor');
    }
  };

  const handleShare = async () => {
    if (!budget) return;
    
    // Validar dados essenciais antes de compartilhar
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

      await Share.share({
        message: message,
        title: `Orçamento - ${budget.clientName}`
      });
    } catch (error) {
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

  const statusColors = {
    draft: '#6b7280',
    sent: '#3b82f6',
    approved: '#10b981',
    completed: '#8b5cf6'
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <MaterialCommunityIcons name="arrow-left" size={24} color="#ffffff" />
        </TouchableOpacity>
        <View style={styles.headerCenter}>
          <Text style={styles.brandName}>BOX JM</Text>
          <Text style={styles.title}>Detalhes</Text>
        </View>
        <View style={styles.headerRight}>
          <TouchableOpacity onPress={handleShare} style={styles.shareButton}>
            <MaterialCommunityIcons name="share-variant" size={24} color="#10b981" />
          </TouchableOpacity>
          <TouchableOpacity onPress={handleEdit} style={styles.editButton}>
            <MaterialCommunityIcons name="pencil" size={24} color="#3b82f6" />
          </TouchableOpacity>
          <TouchableOpacity onPress={handleDelete} style={styles.deleteButton}>
            <MaterialCommunityIcons name="delete" size={24} color="#ef4444" />
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>Cliente</Text>
            <View style={[styles.statusBadge, { backgroundColor: statusColors[budget.status] }]}>
              <Text style={styles.statusText}>{STATUS_LABELS[budget.status]}</Text>
            </View>
          </View>
          <Text style={styles.clientName}>{budget.clientName}</Text>
          {budget.clientPhone && (
            <View style={styles.infoRow}>
              <MaterialCommunityIcons name="phone" size={16} color="#9ca3af" />
              <Text style={styles.infoText}>{budget.clientPhone}</Text>
            </View>
          )}
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Veículo</Text>
          <Text style={styles.vehicleName}>
            {budget.vehicleBrand} {budget.vehicleModel}
          </Text>
          <View style={styles.infoRow}>
            <MaterialCommunityIcons name="car" size={16} color="#9ca3af" />
            <Text style={styles.infoText}>Tipo: {budget.vehicleType}</Text>
          </View>
          <View style={styles.infoRow}>
            <MaterialCommunityIcons name="calculator" size={16} color="#ef4444" />
            <Text style={styles.infoText}>Multiplicador: x{budget.multiplier.toFixed(1)}</Text>
          </View>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Serviços</Text>
          {budget.items.map((item, index) => (
            <View key={index} style={styles.serviceRow}>
              <View style={styles.serviceInfo}>
                <Text style={styles.serviceName}>{item.serviceName}</Text>
                <Text style={styles.serviceDetail}>
                  R$ {item.basePrice.toFixed(2).replace('.', ',')} x {item.quantity}
                </Text>
              </View>
              <Text style={styles.serviceTotal}>
                R$ {(item.basePrice * item.quantity).toFixed(2).replace('.', ',')}
              </Text>
            </View>
          ))}
        </View>

        {budget.notes && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Observações</Text>
            <Text style={styles.notesText}>{budget.notes}</Text>
          </View>
        )}

        <View style={styles.totalsCard}>
          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>Subtotal:</Text>
            <Text style={styles.totalValue}>R$ {budget.subtotal.toFixed(2).replace('.', ',')}</Text>
          </View>
          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>Multiplicador:</Text>
            <Text style={styles.totalValue}>x{budget.multiplier.toFixed(1)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.totalRow}>
            <Text style={styles.finalLabel}>Total:</Text>
            <View style={styles.totalValueContainer}>
              <Text style={styles.finalValue}>R$ {budget.total.toFixed(2).replace('.', ',')}</Text>
              <TouchableOpacity onPress={handleEditTotal} style={styles.editTotalButton}>
                <MaterialCommunityIcons name="pencil" size={20} color="#3b82f6" />
              </TouchableOpacity>
            </View>
          </View>
        </View>

        <View style={styles.actionsCard}>
          <Text style={styles.cardTitle}>Atualizar Status</Text>
          <View style={styles.statusButtons}>
            {(['sent', 'approved', 'completed'] as const).map((status) => (
              <TouchableOpacity
                key={status}
                style={[
                  styles.statusButton,
                  budget.status === status && { backgroundColor: statusColors[status] }
                ]}
                onPress={() => handleStatusChange(status)}
              >
                <Text style={styles.statusButtonText}>{STATUS_LABELS[status]}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <View style={styles.metadata}>
          <Text style={styles.metadataText}>
            Criado em {new Date(budget.createdAt).toLocaleString('pt-BR')}
          </Text>
        </View>
      </ScrollView>

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
                <MaterialCommunityIcons name="close" size={24} color="#9ca3af" />
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
                  placeholder="0.00"
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
                style={[styles.modalButton, styles.saveButton]}
                onPress={handleSaveNewTotal}
              >
                <Text style={styles.saveButtonText}>Salvar</Text>
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
    gap: 8
  },
  shareButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#1f1f1f',
    justifyContent: 'center',
    alignItems: 'center'
  },
  editButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
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
  deleteButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#1f1f1f',
    justifyContent: 'center',
    alignItems: 'center'
  },
  title: {
    fontSize: 24,
    fontWeight: '800',
    color: '#ffffff'
  },
  content: {
    padding: 20,
    paddingBottom: 40
  },
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
    fontSize: 14,
    fontWeight: '600',
    color: '#9ca3af',
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 0.5
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
    marginBottom: 8
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
  serviceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#2f2f2f'
  },
  serviceInfo: {
    flex: 1
  },
  serviceName: {
    fontSize: 15,
    fontWeight: '600',
    color: '#ffffff',
    marginBottom: 4
  },
  serviceDetail: {
    fontSize: 13,
    color: '#9ca3af'
  },
  serviceTotal: {
    fontSize: 16,
    fontWeight: '700',
    color: '#ef4444'
  },
  notesText: {
    fontSize: 14,
    color: '#d1d5db',
    lineHeight: 20
  },
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
    backgroundColor: '#2f2f2f',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center'
  },
  statusButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#ffffff'
  },
  metadata: {
    alignItems: 'center',
    paddingVertical: 12
  },
  metadataText: {
    fontSize: 12,
    color: '#6b7280'
  },
  totalValueContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12
  },
  editTotalButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#1f2937',
    justifyContent: 'center',
    alignItems: 'center'
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
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
    marginBottom: 16
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
    fontSize: 14,
    fontWeight: '600',
    color: '#d1d5db',
    marginBottom: 8
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
    fontSize: 24,
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
    backgroundColor: '#2f2f2f'
  },
  cancelButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#9ca3af'
  },
  saveButton: {
    backgroundColor: '#ef4444'
  },
  saveButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#ffffff'
  }
});