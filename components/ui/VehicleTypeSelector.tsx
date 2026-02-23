import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { VehicleType } from '@/types/budget';
import { VEHICLE_MULTIPLIERS } from '@/constants/services';

interface VehicleTypeSelectorProps {
  selected: VehicleType;
  onSelect: (type: VehicleType) => void;
}

export const VehicleTypeSelector = React.memo(({ selected, onSelect }: VehicleTypeSelectorProps) => {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Tipo de Veículo</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
        {VEHICLE_MULTIPLIERS.map((vehicle) => (
          <TouchableOpacity
            key={vehicle.type}
            style={[
              styles.option,
              selected === vehicle.type && styles.optionSelected
            ]}
            onPress={() => onSelect(vehicle.type)}
            activeOpacity={0.7}
          >
            <MaterialCommunityIcons
              name={vehicle.icon as any}
              size={32}
              color={selected === vehicle.type ? '#ef4444' : '#6b7280'}
            />
            <Text style={[
              styles.label,
              selected === vehicle.type && styles.labelSelected
            ]}>
              {vehicle.label}
            </Text>
            <Text style={[
              styles.multiplier,
              selected === vehicle.type && styles.multiplierSelected
            ]}>
              x{vehicle.multiplier.toFixed(1)}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );
});

const styles = StyleSheet.create({
  container: {
    marginBottom: 20
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    color: '#ffffff',
    marginBottom: 12
  },
  scrollContent: {
    gap: 10,
    paddingRight: 16
  },
  option: {
    width: 100,
    backgroundColor: '#1f1f1f',
    borderRadius: 12,
    padding: 12,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#2f2f2f'
  },
  optionSelected: {
    borderColor: '#ef4444',
    backgroundColor: '#2a1414'
  },
  label: {
    fontSize: 13,
    fontWeight: '600',
    color: '#9ca3af',
    marginTop: 8
  },
  labelSelected: {
    color: '#ffffff'
  },
  multiplier: {
    fontSize: 12,
    fontWeight: '700',
    color: '#6b7280',
    marginTop: 2
  },
  multiplierSelected: {
    color: '#ef4444'
  }
});