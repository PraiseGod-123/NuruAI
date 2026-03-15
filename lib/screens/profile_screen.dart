import 'package:flutter/material.dart';
import '../utils/nuru_colors.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'User';
  String _userEmail = 'user@example.com';
  String _diagnosis = 'ASD';
  int _age = 20;

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _userName = widget.userData!['name'] ?? 'User';
      _userEmail = widget.userData!['email'] ?? 'user@example.com';
      _diagnosis = widget.userData!['diagnosis'] ?? 'ASD';
      _age = widget.userData!['age'] ?? 20;
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: NuruColors.error),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NuruColors.nightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 24),

              // Header with back button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: NuruColors.nightCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    SizedBox(width: 48),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Profile Avatar with gradient
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF667EEA).withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 20),

              // User Name
              Text(
                _userName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 8),

              // User Email
              Text(
                _userEmail,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),

              SizedBox(height: 32),

              // Info Cards Grid
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.cake_rounded,
                        label: 'Age',
                        value: '$_age years',
                        gradient: [Color(0xFFFA709A), Color(0xFFFFE985)],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.psychology_rounded,
                        label: 'Diagnosis',
                        value: _diagnosis,
                        gradient: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Settings Options
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildSettingCard(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      gradient: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                      onTap: () {
                        // TODO: Navigate to edit profile
                      },
                    ),

                    SizedBox(height: 16),

                    _buildSettingCard(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage your notification preferences',
                      gradient: [Color(0xFFFF6B9D), Color(0xFFC239B3)],
                      onTap: () {
                        // TODO: Navigate to notifications settings
                      },
                    ),

                    SizedBox(height: 16),

                    _buildSettingCard(
                      icon: Icons.security_rounded,
                      title: 'Privacy & Security',
                      subtitle: 'Control your privacy settings',
                      gradient: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                      onTap: () {
                        // TODO: Navigate to privacy settings
                      },
                    ),

                    SizedBox(height: 16),

                    _buildSettingCard(
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Customize your app theme',
                      gradient: [Color(0xFFF093FB), Color(0xFFF5576C)],
                      onTap: () {
                        // TODO: Navigate to appearance settings
                      },
                    ),

                    SizedBox(height: 16),

                    _buildSettingCard(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get help and contact support',
                      gradient: [Color(0xFF4E54C8), Color(0xFF8F94FB)],
                      onTap: () {
                        // TODO: Navigate to help
                      },
                    ),

                    SizedBox(height: 16),

                    _buildSettingCard(
                      icon: Icons.info_outline_rounded,
                      title: 'About NuruAI',
                      subtitle: 'App version and information',
                      gradient: [Color(0xFFFFD89B), Color(0xFF19547B)],
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text('About NuruAI'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Version 1.0.0'),
                                SizedBox(height: 8),
                                Text('AI-Powered Autism Care'),
                                SizedBox(height: 8),
                                Text('© 2024 NuruAI'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 32),

                    // Logout Button
                    GestureDetector(
                      onTap: _handleLogout,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: NuruColors.nightCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: NuruColors.error.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: NuruColors.error,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: NuruColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: NuruColors.nightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
