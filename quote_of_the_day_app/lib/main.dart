

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';



class Proverb {
  final String content;
  final String originator;

  Proverb(this.content, this.originator);
}



class QuoteViewModel extends ChangeNotifier {
  final List<Proverb> _proverbCollection = [
    Proverb("The best way to predict the future is to create it.", "Peter Drucker"),
    Proverb("Life is 10% what happens to us and 90% how we react to it.", "Charles R. Swindoll"),
    Proverb("Your time is limited, so don’t waste it living someone else’s life.", "Steve Jobs"),
    Proverb("The only impossible journey is the one you never begin.", "Tony Robbins"),
    Proverb("Strive not to be a success, but rather to be of value.", "Albert Einstein"),
  ];

  late Proverb _activeProverb;
  final List<Proverb> _savedProverbs = [];
  bool _isDarkTheme = false;

  Proverb get activeProverb => _activeProverb;
  List<Proverb> get savedProverbs => _savedProverbs;
  bool get isDarkTheme => _isDarkTheme;

  QuoteViewModel() {
    _activeProverb = _proverbCollection.first;
  }

  void selectNewProverb() {
    Proverb candidate;
    do {
      candidate = _proverbCollection[Random().nextInt(_proverbCollection.length)];
    } while (candidate.content == _activeProverb.content);
    _activeProverb = candidate;
    notifyListeners();
  }

  void manageFavoriteStatus() {
    if (isCurrentProverbSaved()) {
      _savedProverbs.removeWhere((p) => p.content == _activeProverb.content);
    } else {
      _savedProverbs.add(_activeProverb);
    }
    notifyListeners();
  }

  bool isCurrentProverbSaved() {
    return _savedProverbs.any((p) => p.content == _activeProverb.content);
  }

  void removeSaved(Proverb proverb) {
    _savedProverbs.removeWhere((p) => p.content == proverb.content);
    notifyListeners();
  }
  
  void switchTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
  }
}



class AppThemes {
  static final light = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.teal,
    scaffoldBackgroundColor: const Color.fromARGB(255, 252, 252, 252),
    cardColor: const Color.fromARGB(255, 1, 211, 204),
    textTheme: GoogleFonts.sourceSans3TextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black87),
      titleTextStyle: GoogleFonts.sourceSans3(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w600),
    ),
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.tealAccent,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    cardColor: const Color(0xFF2C2C2C),
    textTheme: GoogleFonts.sourceSans3TextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.sourceSans3(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
    ),
  );
}


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => QuoteViewModel(),
      child: const DailyInspirationApp(),
    ),
  );
}

class DailyInspirationApp extends StatelessWidget {
  const DailyInspirationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<QuoteViewModel>(context);
    return MaterialApp(
      title: 'Daily Inspiration',
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: viewModel.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}



class MainScreen extends StatelessWidget {
  const MainScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<QuoteViewModel>(context);
    final proverb = viewModel.activeProverb;
    final isSaved = viewModel.isCurrentProverbSaved();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspiration for Today'),
        actions: [
          IconButton(
            icon: Icon(viewModel.isDarkTheme ? Icons.wb_sunny_outlined : Icons.nightlight_round),
            onPressed: viewModel.switchTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SavedProverbsScreen()),
            ),
            tooltip: 'Saved Quotes',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QuoteDisplayCard(proverb: proverb),
              const SizedBox(height: 50),
              ControlPanel(
                isSaved: isSaved,
                onFavorite: viewModel.manageFavoriteStatus,
                onShare: () => Share.share('"${proverb.content}" - ${proverb.originator}'),
                onRefresh: viewModel.selectNewProverb,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedProverbsScreen extends StatelessWidget {
  const SavedProverbsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<QuoteViewModel>(context);
    final saved = viewModel.savedProverbs;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Saved Collection')),
      body: saved.isEmpty
          ? const Center(
              child: Text('Your collection is empty.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: saved.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final proverb = saved[index];
                return ListTile(
                  title: Text('"${proverb.content}"'),
                  subtitle: Text("- ${proverb.originator}"),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300),
                    onPressed: () => viewModel.removeSaved(proverb),
                  ),
                );
              },
            ),
    );
  }
}


class QuoteDisplayCard extends StatelessWidget {
  final Proverb proverb;
  const QuoteDisplayCard({super.key, required this.proverb});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote_sharp, color: Theme.of(context).primaryColor, size: 30),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: Text(
              proverb.content,
              key: ValueKey(proverb.content),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          Text("— ${proverb.originator}", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }
}

class ControlPanel extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onRefresh;

  const ControlPanel({
    super.key,
    required this.isSaved,
    required this.onFavorite,
    required this.onShare,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        CircularIconButton(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
          label: 'Save',
          onTap: onFavorite,
          color: isSaved ? Colors.amber : null,
        ),
        CircularIconButton(icon: Icons.share_outlined, label: 'Share', onTap: onShare),
        CircularIconButton(icon: Icons.sync, label: 'New', onTap: onRefresh),
      ],
    );
  }
}

class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const CircularIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
            ),
            child: Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
        ],
      ),
    );
  }
}
