import React, { useState } from 'react';
import { View, Text, SectionList, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useCatalog } from '@/hooks/useCatalog';
import { ServiceEditor } from '@/components/ui/ServiceEditor';
import { ServiceItem as ServiceItemType } from '@/types/budget';
import { CATEGORY_LABELS } from '@/constants/services';

export default function ServicesScreen() {
  const insets = useSafeAreaInsets();
  const { services, loading, saveService, deleteService } = useCatalog();
  const [expandedCategory, setExpandedCategory] = useState<string | null>('exterior');
  const [editingService, setEditingService] = useState<ServiceItemType | null>(null);
  const [editorVisible, setEditorVisible] = useState(false);

  const sections = Object.entries(
    services.reduce((acc, service) => {
      if (!acc[service.category]) acc[service.category] = [];
      acc[service.category].push(service);
      return acc;
    }, {} as Record<string, ServiceItemType[]>)
  ).map(([category, services]) => ({
    title: CATEGORY_LABELS[category as keyof typeof CATEGORY_LABELS],
    category,
    data: services
  }));

  const categoryIcons = {
    exterior: 'car-wash',
    interior: 'car-seat',
    protection: 'shield-car',
    detailing: 'auto-fix'
  };

  const handleCreateNew = () => {
    setEditingService(null);
    setEditorVisible(true);
  };

  const handleEditService = (service: ServiceItemType) => {
    setEditingService(service);
    setEditorVisible(true);
  };

  const handleSaveService = async (service: ServiceItemType) => {
    await saveService(service);
  };

  const handleDeleteService = async (id: string) => {
    await deleteService(id);
  };

  if (loading) {
    return (
      <View style={[styles.container, styles.centered, { paddingTop: insets.top }]}>
        <ActivityIndicator size="large" color="#ef4444" />
      </View>
    );
  }

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <View style={styles.header}>
        <View style={styles.logoRow}>
          <View style={styles.logoAccentBar} />
          <View>
            <Text style={styles.brandName}>BOX JM</Text>
            <Text style={styles.title}>Catálogo</Text>
          </View>
        </View>
        <TouchableOpacity style={styles.addButton} onPress={handleCreateNew}>
          <MaterialCommunityIcons name="plus" size={24} color="#ffffff" />
        </TouchableOpacity>
      </View>

      <SectionList
        sections={sections}
        keyExtractor={(item) => item.id}
        renderSectionHeader={({ section }) => (
          <TouchableOpacity
            style={styles.sectionHeader}
            onPress={() => setExpandedCategory(
              expandedCategory === section.category ? null : section.category
            )}
            activeOpacity={0.7}
          >
            <View style={styles.sectionTitleContainer}>
              <MaterialCommunityIcons
                name={categoryIcons[section.category as keyof typeof categoryIcons]}
                size={24}
                color="#ef4444"
              />
              <Text style={styles.sectionTitle}>{section.title}</Text>
              <View style={styles.badge}>
                <Text style={styles.badgeText}>{section.data.length}</Text>
              </View>
            </View>
            <MaterialCommunityIcons
              name={expandedCategory === section.category ? 'chevron-up' : 'chevron-down'}
              size={24}
              color="#9ca3af"
            />
          </TouchableOpacity>
        )}
        renderItem={({ item, section }) => {
          if (expandedCategory !== section.category) return null;
          return (
            <TouchableOpacity
              style={styles.serviceItem}
              onPress={() => handleEditService(item)}
              activeOpacity={0.7}
            >
              <View style={styles.serviceContent}>
                <Text style={styles.serviceName}>{item.name}</Text>
                {item.description && (
                  <Text style={styles.serviceDescription}>{item.description}</Text>
                )}
              </View>
              <View style={styles.serviceRight}>
                <Text style={styles.servicePrice}>
                  R$ {item.basePrice.toFixed(2).replace('.', ',')}
                </Text>
                <MaterialCommunityIcons name="pencil" size={18} color="#6b7280" />
              </View>
            </TouchableOpacity>
          );
        }}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
      />

      <ServiceEditor
        visible={editorVisible}
        service={editingService}
        onClose={() => setEditorVisible(false)}
        onSave={handleSaveService}
        onDelete={handleDeleteService}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a'
  },
  centered: {
    justifyContent: 'center',
    alignItems: 'center'
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#1f1f1f'
  },
  logoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14
  },
  logoAccentBar: {
    width: 3,
    height: 40,
    backgroundColor: '#ef4444',
    borderRadius: 2
  },
  brandName: {
    fontSize: 13,
    fontWeight: '900',
    color: '#ef4444',
    letterSpacing: 2.5,
    marginBottom: 3
  },
  title: {
    fontSize: 26,
    fontWeight: '800',
    color: '#ffffff'
  },
  addButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#ef4444',
    justifyContent: 'center',
    alignItems: 'center'
  },
  listContent: {
    padding: 20
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#1f1f1f',
    padding: 16,
    borderRadius: 12,
    marginBottom: 8
  },
  sectionTitleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#ffffff'
  },
  badge: {
    backgroundColor: '#ef4444',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#ffffff'
  },
  serviceItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#1f1f1f',
    padding: 16,
    borderRadius: 12,
    marginBottom: 8,
    marginLeft: 12,
    borderLeftWidth: 3,
    borderLeftColor: '#ef4444'
  },
  serviceContent: {
    flex: 1
  },
  serviceName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#ffffff',
    marginBottom: 4
  },
  serviceDescription: {
    fontSize: 13,
    color: '#9ca3af'
  },
  serviceRight: {
    alignItems: 'flex-end',
    gap: 4
  },
  servicePrice: {
    fontSize: 18,
    fontWeight: '800',
    color: '#ef4444'
  }
});