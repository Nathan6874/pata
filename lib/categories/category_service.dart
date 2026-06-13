import 'package:pata/models/category_rules.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final List<CategoryRule> _rules = [
    const CategoryRule(
      name: 'Factures',
      keywords: ['cie', 'electricité', 'eau', 'sodeci', 'canal+'],
      priority: 1,
    ),
    const CategoryRule(
      name: 'Télécom',
      keywords: ['recharge', 'internet', 'appel', 'crédit', 'forfait', 'mtn', 'orange', 'moov'],
      priority: 2,
    ),
    const CategoryRule(
      name: 'Transport',
      keywords: ['taxi', 'gbaka', 'warren', 'bus', 'yango', 'essence', 'carburant', 'metro'],
      priority: 3,
    ),
    const CategoryRule(
      name: 'Nourriture',
      keywords: [
        'tomate', 'piment', 'oignon', 'avocat', 'riz', 'pain', 'lait', 'biscuit', 'cerelac',
        'viande', 'poisson', 'fruit', 'légume', 'legume', 'pomme', 'milo', 'bonbon',
        'banane', 'mangue', 'orange', 'ananas', 'farine', 'sucre', 'café', 'sucrérie',
        'sel', 'huile', 'beurre', 'fromage', 'yaourt', 'yoplait', 'œuf', 'oeuf', 'Attiéké',
        'Alloco', 'Foutou', 'Garba', 'Poisson braisé', 'igname', 'Foufou', 'Placali',
        'Poulet braisé', 'Frites', 'Pizza', 'Hamburger', 'Sandwich', 'Sushi', 'Spaghetti', 
        'porc', 'bœuf', 'boeuf', 'poulet'
      ],
      priority: 4,
    ),
    const CategoryRule(
      name: 'Autre',
      keywords: [],
      priority: 99,
    ),
  ];

  String categorize(String motif) {
    final motifLower = motif.toLowerCase().trim();
    
    if (motifLower.isEmpty) return 'Autre';
    
    final sortedRules = List.of(_rules)..sort((a, b) => a.priority.compareTo(b.priority));
    
    for (final rule in sortedRules) {
      for (final keyword in rule.keywords) {
        if (motifLower.contains(keyword)) {
          return rule.name;
        }
      }
    }
    
    return 'Autre';
  }

  List<CategoryRule> get rules => List.unmodifiable(_rules);
}