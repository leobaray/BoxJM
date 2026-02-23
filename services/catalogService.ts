import { getSupabaseClient } from '@/template';
import { ServiceItem } from '@/types/budget';

// Usar o cliente Supabase pré-configurado do template
const getClient = () => getSupabaseClient();

export const catalogService = {
  async getCustomServices(): Promise<ServiceItem[]> {
    try {
      const supabase = getClient();
      const { data, error } = await supabase
        .from('custom_services')
        .select('*')
        .order('created_at', { ascending: true });

      if (error) {
        console.error('Error loading custom services:', error);
        return [];
      }

      if (!data || data.length === 0) {
        return [];
      }

      // Converter snake_case para camelCase
      return data.map(service => ({
        id: service.id,
        name: service.name,
        basePrice: service.base_price,
        category: service.category,
        description: service.description
      }));
    } catch (error) {
      console.error('Error loading custom services:', error);
      return [];
    }
  },

  async saveCustomService(service: ServiceItem): Promise<ServiceItem> {
    try {
      const supabase = getClient();
      const dbService = {
        id: service.id,
        name: service.name,
        base_price: service.basePrice,
        category: service.category,
        description: service.description || null
      };

      // Tentar inserir, se já existir, atualizar
      const { data, error } = await supabase
        .from('custom_services')
        .upsert([dbService], { onConflict: 'id' })
        .select()
        .single();

      if (error) {
        console.error('Error saving custom service:', error);
        throw error;
      }

      // Converter snake_case para camelCase
      return {
        id: data.id,
        name: data.name,
        basePrice: data.base_price,
        category: data.category,
        description: data.description
      };
    } catch (error) {
      console.error('Error saving custom service:', error);
      throw error;
    }
  },

  async deleteCustomService(id: string): Promise<void> {
    try {
      const supabase = getClient();
      const { error } = await supabase
        .from('custom_services')
        .delete()
        .eq('id', id);

      if (error) {
        console.error('Error deleting custom service:', error);
        throw error;
      }
    } catch (error) {
      console.error('Error deleting custom service:', error);
      throw error;
    }
  },

  async updateServicePrice(id: string, newPrice: number): Promise<void> {
    try {
      const supabase = getClient();
      const { error } = await supabase
        .from('custom_services')
        .update({ base_price: newPrice })
        .eq('id', id);

      if (error) {
        console.error('Error updating service price:', error);
        throw error;
      }
    } catch (error) {
      console.error('Error updating service price:', error);
      throw error;
    }
  }
};