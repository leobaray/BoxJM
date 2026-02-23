import { createClient } from '@supabase/supabase-js';
import { Budget, BudgetItem, VehicleType } from '@/types/budget';
import { VEHICLE_MULTIPLIERS } from '@/constants/services';

// Configuração do cliente Supabase
const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!;
const supabase = createClient(supabaseUrl, supabaseKey);

export const budgetService = {
  async getAllBudgets(): Promise<Budget[]> {
    try {
      const { data, error } = await supabase
        .from('budgets')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error loading budgets:', error);
        return [];
      }

      if (!data || data.length === 0) {
        return [];
      }

      // Converter snake_case para camelCase
      return data.map(budget => ({
        id: budget.id,
        clientName: budget.client_name || '',
        clientPhone: budget.client_phone || '',
        vehicleBrand: budget.vehicle_brand || '',
        vehicleModel: budget.vehicle_model || '',
        vehicleType: budget.vehicle_type || 'medium',
        items: budget.items || [],
        subtotal: budget.subtotal || 0,
        multiplier: budget.multiplier || 1,
        total: budget.total || 0,
        status: budget.status || 'draft',
        notes: budget.notes || '',
        createdAt: budget.created_at
      }));
    } catch (error) {
      console.error('Error loading budgets:', error);
      return [];
    }
  },

  async getBudgetById(id: string): Promise<Budget | null> {
    try {
      const { data, error } = await supabase
        .from('budgets')
        .select('*')
        .eq('id', id)
        .single();

      if (error) {
        console.error('Error loading budget:', error);
        return null;
      }

      if (!data) {
        return null;
      }

      // Converter snake_case para camelCase
      return {
        id: data.id,
        clientName: data.client_name || '',
        clientPhone: data.client_phone || '',
        vehicleBrand: data.vehicle_brand || '',
        vehicleModel: data.vehicle_model || '',
        vehicleType: data.vehicle_type || 'medium',
        items: data.items || [],
        subtotal: data.subtotal || 0,
        multiplier: data.multiplier || 1,
        total: data.total || 0,
        status: data.status || 'draft',
        notes: data.notes || '',
        createdAt: data.created_at
      };
    } catch (error) {
      console.error('Error loading budget:', error);
      return null;
    }
  },

  async createBudget(budget: Omit<Budget, 'id' | 'createdAt'>): Promise<Budget> {
    try {
      const newBudget = {
        client_name: budget.clientName,
        client_phone: budget.clientPhone,
        vehicle_brand: budget.vehicleBrand,
        vehicle_model: budget.vehicleModel,
        vehicle_type: budget.vehicleType,
        items: budget.items,
        subtotal: budget.subtotal,
        multiplier: budget.multiplier,
        total: budget.total,
        status: budget.status,
        notes: budget.notes || null
      };

      const { data, error } = await supabase
        .from('budgets')
        .insert([newBudget])
        .select()
        .single();

      if (error) {
        console.error('Error creating budget:', error);
        throw error;
      }

      // Converter snake_case para camelCase
      return {
        id: data.id,
        clientName: data.client_name,
        clientPhone: data.client_phone,
        vehicleBrand: data.vehicle_brand,
        vehicleModel: data.vehicle_model,
        vehicleType: data.vehicle_type,
        items: data.items,
        subtotal: data.subtotal,
        multiplier: data.multiplier,
        total: data.total,
        status: data.status,
        notes: data.notes,
        createdAt: data.created_at
      };
    } catch (error) {
      console.error('Error creating budget:', error);
      throw error;
    }
  },

  async updateBudget(id: string, updates: Partial<Budget>): Promise<Budget> {
    try {
      // Converter camelCase para snake_case
      const dbUpdates: any = {};
      if (updates.clientName !== undefined) dbUpdates.client_name = updates.clientName;
      if (updates.clientPhone !== undefined) dbUpdates.client_phone = updates.clientPhone;
      if (updates.vehicleBrand !== undefined) dbUpdates.vehicle_brand = updates.vehicleBrand;
      if (updates.vehicleModel !== undefined) dbUpdates.vehicle_model = updates.vehicleModel;
      if (updates.vehicleType !== undefined) dbUpdates.vehicle_type = updates.vehicleType;
      if (updates.items !== undefined) dbUpdates.items = updates.items;
      if (updates.subtotal !== undefined) dbUpdates.subtotal = updates.subtotal;
      if (updates.multiplier !== undefined) dbUpdates.multiplier = updates.multiplier;
      if (updates.total !== undefined) dbUpdates.total = updates.total;
      if (updates.status !== undefined) dbUpdates.status = updates.status;
      if (updates.notes !== undefined) dbUpdates.notes = updates.notes;

      const { data, error } = await supabase
        .from('budgets')
        .update(dbUpdates)
        .eq('id', id)
        .select()
        .single();

      if (error) {
        console.error('Error updating budget:', error);
        throw error;
      }

      // Converter snake_case para camelCase
      return {
        id: data.id,
        clientName: data.client_name,
        clientPhone: data.client_phone,
        vehicleBrand: data.vehicle_brand,
        vehicleModel: data.vehicle_model,
        vehicleType: data.vehicle_type,
        items: data.items,
        subtotal: data.subtotal,
        multiplier: data.multiplier,
        total: data.total,
        status: data.status,
        notes: data.notes,
        createdAt: data.created_at
      };
    } catch (error) {
      console.error('Error updating budget:', error);
      throw error;
    }
  },

  async deleteBudget(id: string): Promise<void> {
    try {
      console.log('=== Service: INICIANDO DELETE ===');
      console.log('ID recebido:', id);
      console.log('Tipo do ID:', typeof id);
      
      // Primeiro, verificar se o orçamento existe
      const { data: existingBudget, error: findError } = await supabase
        .from('budgets')
        .select('id, client_name')
        .eq('id', id)
        .single();
      
      if (findError) {
        console.error('Service: Orçamento não encontrado:', findError);
        throw new Error(`Orçamento não encontrado: ${findError.message}`);
      }
      
      console.log('Service: Orçamento encontrado:', existingBudget);
      
      // Agora deletar
      const { error: deleteError } = await supabase
        .from('budgets')
        .delete()
        .eq('id', id);

      if (deleteError) {
        console.error('Service: Erro ao deletar:', deleteError);
        throw new Error(`Falha ao deletar: ${deleteError.message}`);
      }

      console.log('=== Service: DELETE CONCLUÍDO COM SUCESSO ===');
    } catch (error: any) {
      console.error('=== Service: EXCEÇÃO AO DELETAR ===');
      console.error('Erro completo:', error);
      console.error('Mensagem:', error?.message);
      throw error;
    }
  },

  calculateBudgetTotal(items: BudgetItem[], vehicleType: VehicleType): { subtotal: number; multiplier: number; total: number } {
    const subtotal = items.reduce((sum, item) => sum + (item.basePrice * item.quantity), 0);
    const multiplier = VEHICLE_MULTIPLIERS.find(v => v.type === vehicleType)?.multiplier || 1.0;
    const total = subtotal * multiplier;
    
    return {
      subtotal: Math.round(subtotal * 100) / 100,
      multiplier,
      total: Math.round(total * 100) / 100
    };
  }
};