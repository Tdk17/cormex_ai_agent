class LeadLabels {
  const LeadLabels._();

  static const Map<String, String> statuses = <String, String>{
    'new': 'Novo',
    'contacted': 'Contatado',
    'qualified': 'Qualificado',
    'proposal': 'Proposta',
    'won': 'Ganho',
    'lost': 'Perdido',
  };

  static const Map<String, String> sources = <String, String>{
    'manual': 'Manual',
    'import': 'Importação',
    'website': 'Site',
    'whatsapp': 'WhatsApp',
    'instagram': 'Instagram',
    'referral': 'Indicação',
    'campaign': 'Campanha',
  };

  static String status(String value) => statuses[value] ?? value;
  static String source(String value) => sources[value] ?? value;
}
