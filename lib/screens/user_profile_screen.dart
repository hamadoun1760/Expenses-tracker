import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../providers/user_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  
  DateTime? _selectedDateOfBirth;
  Uint8List? _profilePicture;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // Don't load user data by default - only load when editing
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
      _addressController.text = user.address ?? '';
      _bioController.text = user.bio ?? '';
      _selectedDateOfBirth = user.dateOfBirth;
      _profilePicture = user.profilePicture;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 300,
        maxHeight: 300,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profilePicture = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de l\'image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }
      
      final updatedUser = currentUser.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        profilePicture: _profilePicture,
        updatedAt: DateTime.now(),
      );
      
      await userProvider.updateUser(updatedUser);
      
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : () {
                setState(() => _isEditing = false);
                _loadUserData();
              },
              child: const Text('Annuler', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final user = userProvider.currentUser;
            
            if (user == null) {
              return const Center(
                child: Text('Aucun utilisateur connecté'),
              );
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _isEditing ? _pickImage : null,
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF1976D2),
                                      Color(0xFF42A5F5),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1976D2).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _profilePicture != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          _profilePicture!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 70,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                            if (_isEditing) ...[
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.camera_alt, color: Color(0xFF1976D2)),
                                label: const Text(
                                  'Changer la photo',
                                  style: TextStyle(color: Color(0xFF1976D2)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Personal Information Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1976D2).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF1976D2),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Informations personnelles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: _firstNameController,
                                    label: 'Prénom',
                                    hintText: 'Votre prénom',
                                    icon: Icons.badge,
                                    enabled: _isEditing,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Veuillez entrer votre prénom';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    controller: _lastNameController,
                                    label: 'Nom',
                                    hintText: 'Votre nom',
                                    icon: Icons.badge,
                                    enabled: _isEditing,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Veuillez entrer votre nom';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            _buildFormField(
                              controller: _emailController,
                              label: 'Email',
                              hintText: 'votre.email@exemple.com',
                              icon: Icons.email,
                              enabled: _isEditing,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer votre email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                  return 'Veuillez entrer un email valide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            _buildFormField(
                              controller: _phoneController,
                              label: 'Téléphone',
                              hintText: '+243 XXX XXX XXX',
                              icon: Icons.phone,
                              enabled: _isEditing,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 28),
                            _buildDateField(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Additional Information Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1976D2).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.info,
                                    color: Color(0xFF1976D2),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Informations complémentaires',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            _buildFormField(
                              controller: _addressController,
                              label: 'Adresse',
                              hintText: 'Votre adresse',
                              icon: Icons.location_on,
                              enabled: _isEditing,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 28),
                            _buildFormField(
                              controller: _bioController,
                              label: 'Biographie',
                              hintText: 'Parlez un peu de vous',
                              icon: Icons.description,
                              enabled: _isEditing,
                              maxLines: 3,
                              maxLength: 500,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () {
                                setState(() => _isEditing = false);
                                _loadUserData();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                side: const BorderSide(
                                  color: Color(0xFF1976D2),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Annuler',
                                style: TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _saveProfile,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: _isLoading
                                      ? LinearGradient(
                                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                                        )
                                      : const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF1976D2),
                                            Color(0xFF42A5F5),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1976D2).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.save_rounded, size: 18, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text(
                                              'Sauvegarder',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A202C),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD1D5DB),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF1976D2),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              counterText: '',
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date de naissance',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A202C),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isEditing ? _selectDateOfBirth : null,
          child: Container(
            decoration: BoxDecoration(
              color: _isEditing ? Colors.white : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD1D5DB),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _selectedDateOfBirth != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!)
                          : 'Sélectionner une date',
                      style: TextStyle(
                        color: _selectedDateOfBirth != null
                            ? const Color(0xFF1A202C)
                            : const Color(0xFF9CA3AF),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF1976D2),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}