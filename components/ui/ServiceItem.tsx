import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { ServiceItem as ServiceItemType } from '@/types/budget';

interface ServiceItemProps {
  service: ServiceItemType;
  selected: boolean;
  quantity: number;
  onToggle: () => void;
  onQuantityChange: (change: number) => void;
}

export const ServiceItem = React.memo(({ service, selected, quantity, onToggle, onQuantityChange }: ServiceItemProps) => {
  const categoryIcons = {
    exterior: 'car-wash',
    interior: 'car-seat',
    protection: 'shield-car',
    detailing: 'auto-fix'
  };

  return (
    <TouchableOpacity
      style={[styles.container, selected && styles.containerSelected]}
      onPress={onToggle}
      activeOpacity={0.7}
    >
      <View style={styles.iconContainer}>
        <MaterialCommunityIcons
          name={categoryIcons[service.category]}
          size={24}
          color={selected ? '#ef4444' : '#6b7280'}
        />
      </View>

      <View style={styles.content}>
        <Text style={styles.name}>{service.name}</Text>
        {service.description && (
          <Text style={styles.description}>{service.description}</Text>
        )}
        <Text style={styles.price}>R$ {service.basePrice.toFixed(2).replace('.', ',')}</Text>
      </View>

      {selected && (
        <View style={styles.quantityControls}>
          <TouchableOpacity
            style={styles.quantityButton}
            onPress={() => onQuantityChange(-1)}
            disabled={quantity <= 1}
          >
            <MaterialCommunityIcons name="minus" size={18} color="#ffffff" />
          </TouchableOpacity>
          <Text style={styles.quantityText}>{quantity}</Text>
          <TouchableOpacity
            style={styles.quantityButton}
            onPress={() => onQuantityChange(1)}
          >
            <MaterialCommunityIcons name="plus" size={18} color="#ffffff" />
          </TouchableOpacity>
        </View>
      )}
    </TouchableOpacity>
  );
});

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1f1f1f',
    borderRadius: 12,
    padding: 12,
    marginBottom: 8,
    borderWidth: 2,
    borderColor: '#2f2f2f'
  },
  containerSelected: {
    borderColor: '#ef4444',
    backgroundColor: '#2a1414'
  },
  iconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#2f2f2f',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12
  },
  content: {
    flex: 1
  },
  name: {
    fontSize: 15,
    fontWeight: '600',
    color: '#ffffff',
    marginBottom: 2
  },
  description: {
    fontSize: 12,
    color: '#9ca3af',
    marginBottom: 4
  },
  price: {
    fontSize: 14,
    fontWeight: '700',
    color: '#ef4444'
  },
  quantityControls: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8
  },
  quantityButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#ef4444',
    justifyContent: 'center',
    alignItems: 'center'
  },
  quantityText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#ffffff',
    minWidth: 24,
    textAlign: 'center'
  }
});