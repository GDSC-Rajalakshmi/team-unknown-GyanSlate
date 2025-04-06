class StateFruit {
  final String name;
  final String emoji;

  const StateFruit({
    required this.name,
    required this.emoji,
  });
}

class StateFruits {
  static StateFruit getStateFruit(String state) {
    final fruits = {
      'Tamil Nadu': StateFruit(name: 'Jackfruit', emoji: '🥝'),
      'Kerala': StateFruit(name: 'Pineapple', emoji: '🍍'),
      'Karnataka': StateFruit(name: 'Orange', emoji: '🍊'),
      'Andhra Pradesh': StateFruit(name: 'Mango', emoji: '🥭'),
      // Add more states and their fruits as needed
    };

    return fruits[state] ?? StateFruit(name: 'Default', emoji: '🍎');
  }
}