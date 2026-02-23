import React, { useState, useEffect, useMemo } from 'react';
import { View, Text, TextInput, ScrollView, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { useBudgets } from '@/hooks/useBudgets';
import { useCatalog } from '@/hooks/useCatalog';
import { VehicleTypeSelector } from '@/components/ui/VehicleTypeSelector';
import { ServiceItem } from '@/components/ui/ServiceItem';
import { VehicleType, BudgetItem } from '@/types/budget';
import { budgetService } from '@/services/budgetService';
import { CATEGORY_LABELS, VEHICLE_MULTIPLIERS } from '@/constants/services';

const CATEGORY_ORDER = ['exterior', 'interior', 'protection', 'detailing'] as const;

export default function NewBudgetScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { id } = useLocalSearchParams();
  const { budgets, createBudget, updateBudget } = useBudgets();
  const { services } = useCatalog();

  const [clientName, setClientName]       = useState('');
  const [clientPhone, setClientPhone]     = useState('');
  const [vehicleBrand, setVehicleBrand]   = useState('');
  const [vehicleModel, setVehicleModel]   = useState('');
  const [vehicleType, setVehicleType]     = useState<VehicleType>('medium');
  const [selectedServices, setSelectedServices] = useState<Map<string, number>>(new Map());
  const [customPrices, setCustomPrices]   = useState<Map<string, number>>(new Map());
  const [notes, setNotes]                 = useState('');
  const [saving, setSaving]               = useState(false);

  const isEditMode  = !!id;
  const screenTitle = isEditMode ? 'Editar Orçamento' : 'Novo Orçamento';

  useEffect(() => {
    if (isEditMode && id) {
      const budget = budgets.find(b => b.id === id);
      if (budget) {
        setClientName(budget.clientName);
        setClientPhone(budget.clientPhone);
        setVehicleBrand(budget.vehicleBrand);
        setVehicleModel(budget.vehicleModel);
        setVehicleType(budget.vehicleType);
        setNotes(budget.notes || '');

        const servicesMap = new Map<string, number>();
        const pricesMap   = new Map<string, number>();
        budget.items.forEach(item => {
          servicesMap.set(item.serviceId, item.quantity);
          pricesMap.set(item.serviceId, item.basePrice);
        });
        setSelectedServices(servicesMap);
        setCustomPrices(pricesMap);
      }
    }
  }, [id, budgets, isEditMode]);

  const toggleService = (serviceId: string) => {
    setSelectedServices(prev => {
      const next = new Map(prev);
      if (next.has(serviceId)) { next.delete(serviceId); }
      else                     { next.set(serviceId, 1); }
      return next;
    });
  };

  const updatePrice = (serviceId: string, price: number) => {
    setCustomPrices(prev => {
      const next = new Map(prev);
      next.set(serviceId, price);
      return next;
    });
  };

  const updateQuantity = (serviceId: string, change: number) => {
    setSelectedServices(prev => {
      const next     = new Map(prev);
      const current  = next.get(serviceId) || 1;
      next.set(serviceId, Math.max(1, current + change));
      return next;
    });
  };

  const calculateTotal = () => {
    const items: BudgetItem[] = Array.from(selectedServices.entries()).flatMap(([serviceId, quantity]) => {
      const service = services.find(s => s.id === serviceId);
      if (!service) return [];
      return [{ serviceId, serviceName: service.name, basePrice: customPrices.get(serviceId) ?? service.basePrice, quantity }];
    });
    return budgetService.calculateBudgetTotal(items, vehicleType);
  };

  const handleSave = async () => {
    if (saving) return;
    if (!clientName.trim())  { Alert.alert('Campo obrigatório', 'Preencha o nome do cliente');     return; }
    if (!vehicleBrand.trim()){ Alert.alert('Campo obrigatório', 'Preencha a marca do veículo');    return; }
    if (!vehicleModel.trim()){ Alert.alert('Campo obrigatório', 'Preencha o modelo do veículo');   return; }
    if (selectedServices.size === 0) { Alert.alert('Selecione serviços', 'Adicione pelo menos um serviço ao orçamento'); return; }

    setSaving(true);
    try {
      const items: BudgetItem[] = Array.from(selectedServices.entries()).flatMap(([serviceId, quantity]) => {
        const service = services.find(s => s.id === serviceId);
        if (!service) return [];
        return [{ serviceId, serviceName: service.name, basePrice: customPrices.get(serviceId) ?? service.basePrice, quantity }];
      });
      const { subtotal, multiplier, total } = budgetService.calculateBudgetTotal(items, vehicleType);

      if (isEditMode && id) {
        await updateBudget(id as string, { clientName: clientName.trim(), clientPhone: clientPhone.trim(), vehicleBrand: vehicleBrand.trim(), vehicleModel: vehicleModel.trim(), vehicleType, items, subtotal, multiplier, total, notes: notes.trim() });
        Alert.alert('Sucesso', 'Orçamento atualizado com sucesso!', [{ text: 'OK', onPress: () => router.back() }]);
      } else {
        await createBudget({ clientName: clientName.trim(), clientPhone: clientPhone.trim(), vehicleBrand: vehicleBrand.trim(), vehicleModel: vehicleModel.trim(), vehicleType, items, subtotal, multiplier, total, status: 'draft', notes: notes.trim() });
        Alert.alert('Sucesso', 'Orçamento criado com sucesso!', [{ text: 'OK', onPress: () => router.push('/(tabs)') }]);
      }
    } catch {
      Alert.alert('Erro', 'Não foi possível salvar o orçamento. Verifique sua conexão e tente novamente.');
    } finally {
      setSaving(false);
    }
  };

  const { subtotal, multiplier, total } = calculateTotal();

  const vehicleLabel = VEHICLE_MULTIPLIERS.find(v => v.type === vehicleType)?.label ?? vehicleType;

  const servicesByCategory = useMemo(() => {
    return services.reduce((acc, service) => {
      if (!acc[service.category]) acc[service.category] = [];
      acc[service.category].push(service);
      return acc;
    }, {} as Record<string, typeof services>);
  }, [services]);

  const selectedCount = selectedServices.size;
  const servicesSectionTitle = selectedCount > 0
    ? `Serviços  ·  ${selectedCount} selecionado${selectedCount > 1 ? 's' : ''}`
    : 'Serviços';

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          {isEditMode && (
            <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
              <MaterialCommunityIcons name="arrow-left" size={24} color="#ffffff" />
            </TouchableOpacity>
          )}
          <View>
            <Text style={styles.brandName}>BOX JM</Text>
            <Text style={styles.title}>{screenTitle}</Text>
          </View>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>

        {/* Dados do Cliente */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Dados do Cliente</Text>
          <TextInput
            style={styles.input}
            placeholder="Nome do cliente"
            placeholderTextColor="#6b7280"
            value={clientName}
            onChangeText={setClientName}
          />
          <TextInput
            style={styles.input}
            placeholder="Telefone"
            placeholderTextColor="#6b7280"
            value={clientPhone}
            onChangeText={setClientPhone}
            keyboardType="phone-pad"
          />
        </View>

        {/* Veículo */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Veículo</Text>
          <View style={styles.row}>
            <TextInput
              style={[styles.input, styles.halfInput]}
              placeholder="Marca"
              placeholderTextColor="#6b7280"
              value={vehicleBrand}
              onChangeText={setVehicleBrand}
            />
            <TextInput
              style={[styles.input, styles.halfInput]}
              placeholder="Modelo"
              placeholderTextColor="#6b7280"
              value={vehicleModel}
              onChangeText={setVehicleModel}
            />
          </View>
          <VehicleTypeSelector selected={vehicleType} onSelect={setVehicleType} />
        </View>

        {/* Serviços — agrupados por categoria */}
        <View style={styles.section}>
          <View style={styles.sectionTitleRow}>
            <Text style={styles.sectionTitle}>{servicesSectionTitle}</Text>
          </View>

          {CATEGORY_ORDER.map(category => {
            const catServices = servicesByCategory[category];
            if (!catServices?.length) return null;
            return (
              <View key={category} style={styles.categoryGroup}>
                <View style={styles.categoryHeader}>
                  <View style={styles.categoryAccent} />
                  <Text style={styles.categoryLabel}>
                    {CATEGORY_LABELS[category]}
                  </Text>
                </View>
                {catServices.map(service => (
                  <ServiceItem
                    key={service.id}
                    service={service}
                    selected={selectedServices.has(service.id)}
                    quantity={selectedServices.get(service.id) || 1}
                    customPrice={customPrices.get(service.id)}
                    onToggle={() => toggleService(service.id)}
                    onQuantityChange={(change) => updateQuantity(service.id, change)}
                    onPriceChange={(price) => updatePrice(service.id, price)}
                  />
                ))}
              </View>
            );
          })}
        </View>

        {/* Observações */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Observações</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="Observações adicionais..."
            placeholderTextColor="#6b7280"
            value={notes}
            onChangeText={setNotes}
            multiline
            numberOfLines={4}
            textAlignVertical="top"
          />
        </View>

        {/* Totais */}
        {selectedServices.size > 0 && (
          <View style={styles.totalsCard}>
            <View style={styles.totalRow}>
              <Text style={styles.totalLabel}>Subtotal</Text>
              <Text style={styles.totalValue}>R$ {subtotal.toFixed(2).replace('.', ',')}</Text>
            </View>
            <View style={styles.totalRow}>
              <Text style={styles.totalLabel}>Multiplicador ({vehicleLabel})</Text>
              <Text style={styles.totalValue}>x{multiplier.toFixed(1)}</Text>
            </View>
            <View style={styles.divider} />
            <View style={styles.totalRow}>
              <Text style={styles.finalLabel}>Total</Text>
              <Text style={styles.finalValue}>R$ {total.toFixed(2).replace('.', ',')}</Text>
            </View>
          </View>
        )}

        {/* Botão salvar */}
        <TouchableOpacity
          style={[styles.saveButton, (selectedServices.size === 0 || saving) && styles.saveButtonDisabled]}
          onPress={handleSave}
          disabled={selectedServices.size === 0 || saving}
        >
          <MaterialCommunityIcons name="check" size={22} color="#ffffff" />
          <Text style={styles.saveButtonText}>
            {saving ? 'Salvando...' : isEditMode ? 'Salvar Alterações' : 'Criar Orçamento'}
          </Text>
        </TouchableOpacity>

      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a'
  },
  header: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#1f1f1f'
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#1f1f1f',
    justifyContent: 'center',
    alignItems: 'center'
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
  content: {
    padding: 20,
    paddingBottom: 100
  },
  section: {
    marginBottom: 28
  },
  sectionTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#ffffff',
    marginBottom: 12
  },

  /* Category grouping */
  categoryGroup: {
    marginBottom: 12
  },
  categoryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 8
  },
  categoryAccent: {
    width: 3,
    height: 13,
    backgroundColor: '#ef4444',
    borderRadius: 2
  },
  categoryLabel: {
    fontSize: 11,
    fontWeight: '700',
    color: '#6b7280',
    textTransform: 'uppercase',
    letterSpacing: 1
  },

  /* Inputs */
  input: {
    backgroundColor: '#1f1f1f',
    borderWidth: 1,
    borderColor: '#2f2f2f',
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    color: '#ffffff',
    marginBottom: 12
  },
  row: {
    flexDirection: 'row',
    gap: 12
  },
  halfInput: {
    flex: 1
  },
  textArea: {
    height: 100,
    paddingTop: 16
  },

  /* Totals */
  totalsCard: {
    backgroundColor: '#1f1f1f',
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
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

  /* Save button */
  saveButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    backgroundColor: '#ef4444',
    padding: 18,
    borderRadius: 12,
    marginBottom: 20
  },
  saveButtonDisabled: {
    opacity: 0.4
  },
  saveButtonText: {
    fontSize: 17,
    fontWeight: '700',
    color: '#ffffff'
  }
});
