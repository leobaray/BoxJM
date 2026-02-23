import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, TouchableOpacity, Modal, ScrollView, Alert } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { ServiceItem } from '@/types/budget';

interface ServiceEditorProps {
  visible: boolean;
  service: ServiceItem | null;
  onClose: () => void;
  onSave: (service: ServiceItem) => void;
  onDelete?: (id: string) => void;
}

export const ServiceEditor = ({ visible, service, onClose, onSave, onDelete }: ServiceEditorProps) => {
  const [name,        setName]        = useState(service?.name || '');
  const [price,       setPrice]       = useState(service?.basePrice ? service.basePrice.toFixed(2).replace('.', ',') : '');
  const [description, setDescription] = useState(service?.description || '');
  const [category,    setCategory]    = useState<ServiceItem['category']>(service?.category || 'exterior');

  const categories: Array<{ value: ServiceItem['category']; label: string }> = [
    { value: 'exterior',   label: 'Externo'       },
    { value: 'interior',   label: 'Interno'       },
    { value: 'protection', label: 'Proteção'      },
    { value: 'detailing',  label: 'Detalhamento'  }
  ];

  React.useEffect(() => {
    if (visible) {
      if (service) {
        setName(service.name);
        setPrice(service.basePrice.toFixed(2).replace('.', ','));
        setDescription(service.description || '');
        setCategory(service.category);
      } else {
        setName('');
        setPrice('');
        setDescription('');
        setCategory('exterior');
      }
    }
  }, [service, visible]);

  const handleSave = () => {
    const priceValue = parseFloat(price.replace(',', '.'));
    if (!name.trim()) {
      Alert.alert('Campo obrigatório', 'Preencha o nome do serviço');
      return;
    }
    if (isNaN(priceValue) || priceValue <= 0) {
      Alert.alert('Preço inválido', 'Digite um preço válido maior que zero');
      return;
    }
    onSave({
      id:          service?.id || `custom-${Date.now()}`,
      name:        name.trim(),
      basePrice:   priceValue,
      category,
      description: description.trim() || undefined
    });
    onClose();
  };

  const handleDelete = () => {
    if (service && onDelete) {
      onDelete(service.id);
      onClose();
    }
  };

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.overlay}>
        <View style={styles.container}>

          <View style={styles.header}>
            <Text style={styles.title}>
              {service ? 'Editar Serviço' : 'Novo Serviço'}
            </Text>
            <TouchableOpacity onPress={onClose} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
              <MaterialCommunityIcons name="close" size={22} color="#6b7280" />
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Text style={styles.label}>Nome do Serviço</Text>
            <TextInput
              style={styles.input}
              value={name}
              onChangeText={setName}
              placeholder="Ex: Polimento Premium"
              placeholderTextColor="#6b7280"
            />

            <Text style={styles.label}>Preço Base (R$)</Text>
            <TextInput
              style={styles.input}
              value={price}
              onChangeText={setPrice}
              placeholder="0,00"
              placeholderTextColor="#6b7280"
              keyboardType="decimal-pad"
            />

            <Text style={styles.label}>Categoria</Text>
            <View style={styles.categoryGrid}>
              {categories.map(cat => (
                <TouchableOpacity
                  key={cat.value}
                  style={[styles.categoryButton, category === cat.value && styles.categoryButtonSelected]}
                  onPress={() => setCategory(cat.value)}
                  activeOpacity={0.7}
                >
                  <Text style={[styles.categoryText, category === cat.value && styles.categoryTextSelected]}>
                    {cat.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Text style={styles.label}>Descrição (opcional)</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={description}
              onChangeText={setDescription}
              placeholder="Detalhes sobre o serviço..."
              placeholderTextColor="#6b7280"
              multiline
              numberOfLines={3}
              textAlignVertical="top"
            />
          </ScrollView>

          <View style={styles.footer}>
            {service && onDelete && (
              <TouchableOpacity style={styles.deleteButton} onPress={handleDelete} activeOpacity={0.7}>
                <MaterialCommunityIcons name="delete" size={18} color="#ef4444" />
                <Text style={styles.deleteButtonText}>Excluir</Text>
              </TouchableOpacity>
            )}
            <TouchableOpacity style={styles.saveButton} onPress={handleSave} activeOpacity={0.8}>
              <MaterialCommunityIcons name="check" size={18} color="#ffffff" />
              <Text style={styles.saveButtonText}>Salvar</Text>
            </TouchableOpacity>
          </View>

        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.85)',
    justifyContent: 'flex-end'
  },
  container: {
    backgroundColor: '#0f0f0f',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: '90%',
    borderTopWidth: 2,
    borderTopColor: '#ef4444'
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#1f1f1f'
  },
  title: {
    fontSize: 22,
    fontWeight: '800',
    color: '#ffffff'
  },
  content: {
    padding: 20
  },
  label: {
    fontSize: 11,
    fontWeight: '700',
    color: '#6b7280',
    marginBottom: 8,
    marginTop: 16,
    textTransform: 'uppercase',
    letterSpacing: 0.8
  },
  input: {
    backgroundColor: '#1f1f1f',
    borderWidth: 1,
    borderColor: '#2f2f2f',
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    color: '#ffffff'
  },
  textArea: {
    height: 80,
    paddingTop: 16
  },
  categoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8
  },
  categoryButton: {
    flex: 1,
    minWidth: '45%',
    backgroundColor: '#1f1f1f',
    padding: 12,
    borderRadius: 12,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#2f2f2f'
  },
  categoryButtonSelected: {
    borderColor: '#ef4444',
    backgroundColor: '#2a1414'
  },
  categoryText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#6b7280'
  },
  categoryTextSelected: {
    color: '#ffffff'
  },
  footer: {
    flexDirection: 'row',
    gap: 12,
    padding: 20,
    borderTopWidth: 1,
    borderTopColor: '#1f1f1f'
  },
  deleteButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    backgroundColor: '#1f1f1f',
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#ef4444'
  },
  deleteButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#ef4444'
  },
  saveButton: {
    flex: 2,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    backgroundColor: '#ef4444',
    padding: 16,
    borderRadius: 12
  },
  saveButtonText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#ffffff'
  }
});
