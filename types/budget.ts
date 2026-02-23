export type VehicleType = 'small' | 'medium' | 'large' | 'suv' | 'truck';
export type BudgetStatus = 'draft' | 'sent' | 'approved' | 'completed';

export interface ServiceItem {
  id: string;
  name: string;
  basePrice: number;
  category: 'exterior' | 'interior' | 'protection' | 'detailing';
  description?: string;
}

export interface BudgetItem {
  serviceId: string;
  serviceName: string;
  basePrice: number;
  quantity: number;
}

export interface Budget {
  id: string;
  clientName: string;
  clientPhone: string;
  vehicleBrand: string;
  vehicleModel: string;
  vehicleType: VehicleType;
  items: BudgetItem[];
  subtotal: number;
  multiplier: number;
  total: number;
  status: BudgetStatus;
  notes?: string;
  createdAt: string;
}

export interface VehicleMultiplier {
  type: VehicleType;
  label: string;
  multiplier: number;
  icon: string;
}