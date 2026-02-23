import React, { createContext, useState, useEffect, ReactNode } from 'react';
import { ServiceItem } from '@/types/budget';
import { catalogService } from '@/services/catalogService';
import { SERVICE_CATALOG } from '@/constants/services';

interface CatalogContextType {
  services: ServiceItem[];
  loading: boolean;
  refreshServices: () => Promise<void>;
  saveService: (service: ServiceItem) => Promise<void>;
  deleteService: (id: string) => Promise<void>;
  updateServicePrice: (id: string, newPrice: number) => Promise<void>;
}

export const CatalogContext = createContext<CatalogContextType | undefined>(undefined);

export function CatalogProvider({ children }: { children: ReactNode }) {
  const [services, setServices] = useState<ServiceItem[]>([]);
  const [loading, setLoading] = useState(true);

  const refreshServices = async () => {
    try {
      setLoading(true);
      const customServices = await catalogService.getCustomServices();
      
      // Merge default services with custom services
      const defaultIds = SERVICE_CATALOG.map(s => s.id);
      const customOnly = customServices.filter(s => !defaultIds.includes(s.id));
      
      // Update default services with custom prices if they exist
      const mergedDefaults = SERVICE_CATALOG.map(defaultService => {
        const custom = customServices.find(s => s.id === defaultService.id);
        return custom || defaultService;
      });
      
      setServices([...mergedDefaults, ...customOnly]);
    } catch (error) {
      console.error('Error refreshing services:', error);
      setServices(SERVICE_CATALOG);
    } finally {
      setLoading(false);
    }
  };

  const saveService = async (service: ServiceItem) => {
    await catalogService.saveCustomService(service);
    await refreshServices();
  };

  const deleteService = async (id: string) => {
    await catalogService.deleteCustomService(id);
    await refreshServices();
  };

  const updateServicePrice = async (id: string, newPrice: number) => {
    await catalogService.updateServicePrice(id, newPrice);
    await refreshServices();
  };

  useEffect(() => {
    refreshServices();
  }, []);

  return (
    <CatalogContext.Provider value={{
      services,
      loading,
      refreshServices,
      saveService,
      deleteService,
      updateServicePrice
    }}>
      {children}
    </CatalogContext.Provider>
  );
}