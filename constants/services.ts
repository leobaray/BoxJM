import { ServiceItem, VehicleMultiplier } from '@/types/budget';

export const SERVICE_CATALOG: ServiceItem[] = [
  // Exterior
  {
    id: 'ext-wash-basic',
    name: 'Lavagem Básica',
    basePrice: 50,
    category: 'exterior',
    description: 'Lavagem externa completa'
  },
  {
    id: 'ext-wash-premium',
    name: 'Lavagem Premium',
    basePrice: 80,
    category: 'exterior',
    description: 'Lavagem + cera + pneus'
  },
  {
    id: 'ext-polimento',
    name: 'Polimento',
    basePrice: 200,
    category: 'exterior',
    description: 'Polimento técnico'
  },
  {
    id: 'ext-cristalizacao',
    name: 'Cristalização',
    basePrice: 350,
    category: 'exterior',
    description: 'Proteção vitrificada'
  },
  
  // Interior
  {
    id: 'int-aspiracao',
    name: 'Aspiração Completa',
    basePrice: 40,
    category: 'interior',
    description: 'Aspiração de todo interior'
  },
  {
    id: 'int-higienizacao',
    name: 'Higienização',
    basePrice: 150,
    category: 'interior',
    description: 'Limpeza profunda de bancos e carpetes'
  },
  {
    id: 'int-hidratacao',
    name: 'Hidratação de Couro',
    basePrice: 120,
    category: 'interior',
    description: 'Tratamento de bancos de couro'
  },
  
  // Protection
  {
    id: 'prot-vitrificacao',
    name: 'Vitrificação',
    basePrice: 800,
    category: 'protection',
    description: 'Proteção cerâmica 9H'
  },
  {
    id: 'prot-ppf',
    name: 'PPF (Paint Protection Film)',
    basePrice: 1500,
    category: 'protection',
    description: 'Película de proteção de pintura'
  },
  
  // Detailing
  {
    id: 'det-motor',
    name: 'Limpeza de Motor',
    basePrice: 80,
    category: 'detailing',
    description: 'Limpeza e proteção do motor'
  },
  {
    id: 'det-farois',
    name: 'Polimento de Faróis',
    basePrice: 120,
    category: 'detailing',
    description: 'Restauração de faróis'
  }
];

export const VEHICLE_MULTIPLIERS: VehicleMultiplier[] = [
  {
    type: 'small',
    label: 'Pequeno',
    multiplier: 1.0,
    icon: 'car-hatchback'
  },
  {
    type: 'medium',
    label: 'Médio',
    multiplier: 1.2,
    icon: 'car-sedan'
  },
  {
    type: 'large',
    label: 'Grande',
    multiplier: 1.5,
    icon: 'car-estate'
  },
  {
    type: 'suv',
    label: 'SUV',
    multiplier: 1.7,
    icon: 'car-side'
  },
  {
    type: 'truck',
    label: 'Caminhonete',
    multiplier: 2.0,
    icon: 'truck'
  }
];

export const CATEGORY_LABELS = {
  exterior: 'Externo',
  interior: 'Interno',
  protection: 'Proteção',
  detailing: 'Detalhamento'
};

export const STATUS_LABELS = {
  draft: 'Rascunho',
  sent: 'Enviado',
  approved: 'Aprovado',
  completed: 'Concluído'
};