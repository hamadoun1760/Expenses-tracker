import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isChangingPin;
  final VoidCallback? onSuccess;

  const PinSetupScreen({
    super.key,
    this.isChangingPin = false,
    this.onSuccess,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final PageController _pageController = PageController();
  String _currentPin = '';
  String _confirmPin = '';
  String _oldPin = '';
  bool _isLoading = false;
  String _error = '';
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isChangingPin ? 'Modifier le PIN' : 'Configurer le PIN'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (widget.isChangingPin) _buildOldPinPage(),
          _buildNewPinPage(),
          _buildConfirmPinPage(),
        ],
      ),
    );
  }

  Widget _buildOldPinPage() {
    return _buildPinInputPage(
      title: 'PIN actuel',
      subtitle: 'Entrez votre PIN actuel',
      value: _oldPin,
      onChanged: (value) => setState(() => _oldPin = value),
      onComplete: () async {
        setState(() => _isLoading = true);
        final isValid = await SecurityService.verifyPin(_oldPin);
        setState(() => _isLoading = false);

        if (isValid) {
          _nextPage();
        } else {
          setState(() => _error = 'PIN incorrect');
        }
      },
    );
  }

  Widget _buildNewPinPage() {
    return _buildPinInputPage(
      title: widget.isChangingPin ? 'Nouveau PIN' : 'Créer un PIN',
      subtitle: 'Entrez un PIN à 4 chiffres',
      value: _currentPin,
      onChanged: (value) => setState(() => _currentPin = value),
      onComplete: () => _nextPage(),
    );
  }

  Widget _buildConfirmPinPage() {
    return _buildPinInputPage(
      title: 'Confirmer le PIN',
      subtitle: 'Entrez à nouveau votre PIN',
      value: _confirmPin,
      onChanged: (value) => setState(() => _confirmPin = value),
      onComplete: _setupPin,
    );
  }

  Widget _buildPinInputPage({
    required String title,
    required String subtitle,
    required String value,
    required Function(String) onChanged,
    required VoidCallback onComplete,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 120,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Title and subtitle
            Icon(
              Icons.security,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: index < value.length
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    child: index < value.length
                        ? const Icon(Icons.circle, size: 12, color: Colors.white)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_error.isNotEmpty) ...[
              Text(
                _error,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Number keypad
            _buildNumberKeypad(value, onChanged, onComplete),

            const SizedBox(height: 24),

            // Loading indicator
            if (_isLoading)
              const CircularProgressIndicator(),
              
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberKeypad(
    String value,
    Function(String) onChanged,
    VoidCallback onComplete,
  ) {
    return Column(
      children: [
        // Numbers 1-3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [1, 2, 3].map((number) {
            return _buildKeypadButton(
              text: number.toString(),
              onPressed: () => _addDigit(number.toString(), value, onChanged, onComplete),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Numbers 4-6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [4, 5, 6].map((number) {
            return _buildKeypadButton(
              text: number.toString(),
              onPressed: () => _addDigit(number.toString(), value, onChanged, onComplete),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Numbers 7-9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [7, 8, 9].map((number) {
            return _buildKeypadButton(
              text: number.toString(),
              onPressed: () => _addDigit(number.toString(), value, onChanged, onComplete),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // 0 and delete
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 60), // Empty space
            _buildKeypadButton(
              text: '0',
              onPressed: () => _addDigit('0', value, onChanged, onComplete),
            ),
            _buildKeypadButton(
              icon: Icons.backspace_outlined,
              onPressed: () => _removeDigit(value, onChanged),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton({
    String? text,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(30),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onPressed,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Center(
            child: text != null
                ? Text(
                    text,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  )
                : Icon(
                    icon,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
        ),
      ),
    );
  }

  void _addDigit(String digit, String currentValue, Function(String) onChanged, VoidCallback onComplete) {
    if (currentValue.length < 4) {
      HapticFeedback.lightImpact();
      setState(() => _error = '');
      final newValue = currentValue + digit;
      onChanged(newValue);
      
      if (newValue.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), onComplete);
      }
    }
  }

  void _removeDigit(String currentValue, Function(String) onChanged) {
    if (currentValue.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _error = '');
      onChanged(currentValue.substring(0, currentValue.length - 1));
    }
  }

  void _nextPage() {
    _currentPage++;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _setupPin() async {
    if (_currentPin != _confirmPin) {
      setState(() => _error = 'Les PINs ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    if (widget.isChangingPin) {
      success = await SecurityService.changePin(_oldPin, _currentPin);
    } else {
      success = await SecurityService.setupPin(_currentPin);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isChangingPin ? 'PIN modifié avec succès!' : 'PIN configuré avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.of(context).pop();
        }
      }
    } else {
      setState(() => _error = 'Erreur lors de la configuration du PIN');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}