import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';

class PinEntryScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final bool canCancel;

  const PinEntryScreen({
    super.key,
    required this.onSuccess,
    this.canCancel = false,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen>
    with TickerProviderStateMixin {
  String _enteredPin = '';
  String _error = '';
  bool _isLoading = false;
  int _failedAttempts = 0;
  bool _isLocked = false;
  int _lockTimeRemaining = 0;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: widget.canCancel
          ? AppBar(
              title: const Text('Authentification'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         (widget.canCancel ? 160 : 100),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/icon
                Icon(
                  Icons.security,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // App name
                Text(
                  'Expenses Tracker',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 16),

                // Instruction text
                Text(
                  _isLocked ? 'Application verrouillée' : 'Entrez votre PIN',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),

                if (_isLocked) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Essayez dans $_lockTimeRemaining secondes',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // PIN dots with shake animation
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value * 10 * 
                          (1 - _shakeAnimation.value), 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: index < _enteredPin.length
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              child: index < _enteredPin.length
                                  ? const Icon(Icons.circle, size: 12, color: Colors.white)
                                  : null,
                            ),
                          );
                        }),
                      ),
                    );
                  },
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // Failed attempts indicator
                if (_failedAttempts > 0 && !_isLocked) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${3 - _failedAttempts} tentatives restantes',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 16),

                // Number keypad
                if (!_isLocked) _buildNumberKeypad(),

                const SizedBox(height: 24),

                // Loading indicator
                if (_isLoading)
                  const CircularProgressIndicator(),

                const SizedBox(height: 16),

                // Forgot PIN button (if cancellable)
                if (widget.canCancel)
                  TextButton(
                    onPressed: _showForgotPinDialog,
                    child: const Text('PIN oublié?'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberKeypad() {
    return Column(
      children: [
        // Numbers 1-3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [1, 2, 3].map((number) {
            return _buildKeypadButton(
              text: number.toString(),
              onPressed: () => _addDigit(number.toString()),
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
              onPressed: () => _addDigit(number.toString()),
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
              onPressed: () => _addDigit(number.toString()),
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
              onPressed: () => _addDigit('0'),
            ),
            _buildKeypadButton(
              icon: Icons.backspace_outlined,
              onPressed: _removeDigit,
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
      elevation: 2,
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

  void _addDigit(String digit) {
    if (_enteredPin.length < 4 && !_isLocked) {
      HapticFeedback.lightImpact();
      setState(() {
        _error = '';
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _removeDigit() {
    if (_enteredPin.isNotEmpty && !_isLocked) {
      HapticFeedback.lightImpact();
      setState(() {
        _error = '';
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    final isValid = await SecurityService.verifyPin(_enteredPin);

    setState(() => _isLoading = false);

    if (isValid) {
      HapticFeedback.lightImpact();
      widget.onSuccess();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward().then((_) {
        _shakeController.reset();
      });

      setState(() {
        _error = 'PIN incorrect';
        _enteredPin = '';
        _failedAttempts++;
      });

      if (_failedAttempts >= 3) {
        _lockApp();
      }
    }
  }

  void _lockApp() {
    setState(() {
      _isLocked = true;
      _lockTimeRemaining = 30; // 30 seconds lock
    });

    // Start countdown
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _lockTimeRemaining--;
        });
        return _lockTimeRemaining > 0;
      }
      return false;
    }).then((_) {
      if (mounted) {
        setState(() {
          _isLocked = false;
          _failedAttempts = 0;
          _error = '';
        });
      }
    });
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN oublié'),
        content: const Text(
          'Pour réinitialiser votre PIN, vous devez désactiver la sécurité et reconfigurer un nouveau PIN dans les paramètres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }
}