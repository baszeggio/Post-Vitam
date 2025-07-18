class PetStatus {
  final int? id;
  final int hunger;
  final int happiness;
  final int energy;
  final int vitality;
  final int coins;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PetStatus({
    this.id,
    required this.hunger,
    required this.happiness,
    required this.energy,
    required this.vitality,
    required this.coins,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'hunger': hunger,
    'happiness': happiness,
    'energy': energy,
    'vitality': vitality,
    'coins': coins,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory PetStatus.fromMap(Map<String, dynamic> map) => PetStatus(
    id: map['id'],
    hunger: map['hunger'],
    happiness: map['happiness'],
    energy: map['energy'],
    vitality: map['vitality'],
    coins: map['coins'] ?? 20000,
    createdAt: map['created_at'] != null
        ? DateTime.parse(map['created_at'])
        : null,
    updatedAt: map['updated_at'] != null
        ? DateTime.parse(map['updated_at'])
        : null,
  );

  @override
  String toString() {
    return 'PetStatus(id: $id, hunger: $hunger, happiness: $happiness, energy: $energy, vitality: $vitality, coins: $coins, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
