// ignore_for_file: deprecated_member_use, unused_element_parameter

import 'dart:ui';

import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:rajakumari_scheme/core/api_secrets/api_secrets.dart';
import 'package:rajakumari_scheme/core/config/app_config.dart';
import 'package:rajakumari_scheme/core/controllers/store_list_controller.dart';
import 'package:rajakumari_scheme/core/global_widgets/custom_alert_box.dart';
import 'package:rajakumari_scheme/core/models/coredata_model.dart';
import 'package:rajakumari_scheme/core/services/auth_state_service.dart';
import 'package:rajakumari_scheme/features/authentication/view/pages/login_with_phone_page.dart';
import 'package:rajakumari_scheme/features/info/view/pages/policy_page.dart';
import 'package:rajakumari_scheme/features/passbook/view/pages/passbook_page.dart';
import 'package:rajakumari_scheme/features/profile/view/pages/edit_profile_page.dart';
import 'package:rajakumari_scheme/features/profile/view/pages/profile_page.dart';

class AppDrawerWidget extends StatefulWidget {
  final VoidCallback? onSelectPassbook;
  final VoidCallback? onSelectProfile;
  // final VoidCallback? onLoginButton;
  final CoreData? coreData;

  const AppDrawerWidget({
    super.key,
    this.onSelectPassbook,
    this.onSelectProfile,
    this.coreData,

    // this.onLoginButton,
  });

  @override
  State<AppDrawerWidget> createState() => _AppDrawerWidgetState();
}

class _AppDrawerWidgetState extends State<AppDrawerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late CurvedAnimation _animation;
  int? _hoveredIndex;
  final _storeListController = StoreListController();
  final AuthStateService _authStateService = AuthStateService();
  // User data variables
  bool _isLoggedIn = false;
  String _userName = '';
  String _profileImage = '';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeOut,
    );

    // Trigger animation
    _animationController.forward();

    _updateAuthState();
    _authStateService.addListener(_onAuthStateChanged);
  }

  // Handle auth state changes
  void _onAuthStateChanged() {
    _updateAuthState();
  }

  // Update auth state from service
  void _updateAuthState() {
    setState(() {
      _isLoggedIn = _authStateService.isLoggedIn;
      _userName = _authStateService.userName;
      _profileImage = _authStateService.userProfileImage;
    });
  }

  @override
  void dispose() {
    _authStateService.removeListener(_onAuthStateChanged);
    _animationController.dispose();
    super.dispose();
  }

  // Navigate to login page
  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginWithPhonePage(coreData: widget.coreData!),
      ),
    ).then((_) {
      // Refresh auth state when coming back from login page
      _authStateService.checkAuthState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(300 * (1 - _animation.value), 0), // -width to 0
          child: Drawer(
            width: 300,
            backgroundColor: Colors.transparent,
            elevation: 0,

            child: Align(
              alignment: AlignmentGeometry.centerRight,
              child: Stack(
                children: [
                  // Blurred background
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(25),
                              bottomLeft: Radius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Column(
                    children: [
                      _buildDrawerHeader(context),
                      Expanded(child: _buildDrawerItems(context)),
                      _buildFooter(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.3),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFC107), // Amber base
                Color(0xFFFFB300), // Darker amber
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.zero,
              bottomLeft: Radius.zero,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              _isLoggedIn
                  ? _buildLoggedInHeader(context)
                  : _buildLoggedOutHeader(context),
        ),
      ),
    );
  }

  // Header widget when user is logged in
  Widget _buildLoggedInHeader(BuildContext context) {
    return Row(
      children: [
        Hero(
          tag: 'profile_avatar',
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () async {
                  Navigator.of(context).pop(); // Close drawer
                  if (widget.onSelectProfile != null) {
                    widget.onSelectProfile!();
                  } else {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );

                    // Refresh auth state if profile was updated
                    if (result == true) {
                      _authStateService.checkAuthState();
                    }
                  }
                },
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      _profileImage.isNotEmpty
                          ? NetworkImage(
                            "${ApiSecrets.imageBaseUrl}$_profileImage",
                          )
                          : null,
                  child:
                      _profileImage.isEmpty
                          ? const Icon(
                            Icons.person,
                            color: Colors.blue,
                            size: 38,
                          )
                          : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              //  final result=
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
              // if (result == true) {
              //   _loadUserData();
              // }
            },
            child: Text(
              _userName.isNotEmpty ? _userName : 'User',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 22,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // Header widget when user is logged out
  Widget _buildLoggedOutHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to access all features',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (widget.onSelectProfile != null) {
              Navigator.of(context).pop();
              widget.onSelectProfile!();
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) =>
                          LoginWithPhonePage(coreData: widget.coreData!),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Login'),
        ),
      ],
    );
  }

  Widget _buildDrawerItems(BuildContext context) {
    final drawerItems = [
      // _DrawerItem(
      //   icon: Icons.store,
      //   title: 'Our Stores',
      //   onTap: () {
      //     Navigator.of(context).pop(); // Close drawer first
      //     Navigator.of(
      //       context,
      //     ).push(MaterialPageRoute(builder: (context) => const StoresPage()));
      //   },
      // ),
      // _DrawerItem(
      //   icon: Icons.description,
      //   title: 'Our Schemes',
      //   onTap: () {
      //     Navigator.of(context).pop(); // Close drawer first
      //     Navigator.of(context).push(
      //       MaterialPageRoute(builder: (context) => const GoldSchemesPage()),
      //     );
      //   },
      // ),
      _DrawerItem(
        icon: Icons.book,
        title: 'My Passbook',
        onTap: () {
          Navigator.of(context).pop(); // Close drawer
          if (widget.onSelectPassbook != null) {
            widget.onSelectPassbook!();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const PassbookPage()),
            );
          }
        },
      ),
      _isLoggedIn
          ? _DrawerItem(
            icon: Icons.person,
            title: 'Profile',
            onTap: () async {
              Navigator.of(context).pop(); // Close drawer
              if (widget.onSelectProfile != null) {
                widget.onSelectProfile!();
              } else {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );

                // Refresh auth state if profile was updated
                if (result == true) {
                  _authStateService.checkAuthState();
                }
              }
            },
          )
          : _DrawerItem(
            icon: FeatherIcons.logIn,
            title: 'Login',
            onTap: () {
              if (widget.onSelectProfile != null) {
                Navigator.of(context).pop();
                widget.onSelectProfile!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            LoginWithPhonePage(coreData: widget.coreData!),
                  ),
                );
              }
            },
          ),
      _DrawerItem(
        icon: Icons.assignment_return,
        title: 'Refund Policy',
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PolicyPage(title: 'Refund Policy'),
            ),
          );
        },
      ),
      _DrawerItem(
        icon: Icons.assignment_returned,
        title: 'Return Policy',
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PolicyPage(title: 'Return Policy'),
            ),
          );
        },
      ),
      _DrawerItem(
        icon: Icons.local_shipping,
        title: 'Shipping Policy',
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PolicyPage(title: 'Shipping Policy'),
            ),
          );
        },
      ),
      _DrawerItem(
        icon: Icons.privacy_tip,
        title: 'Privacy Policy',
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PolicyPage(title: 'Privacy Policy'),
            ),
          );
        },
      ),
      _DrawerItem(
        icon: Icons.gavel,
        title: 'Terms and Conditions',
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => const PolicyPage(title: 'Terms and Conditions'),
            ),
          );
        },
      ),
      // _DrawerItem(
      //   icon: Icons.support_agent,
      //   title: 'Support',
      //   onTap: () {
      //     Navigator.of(context).pop();
      //   },
      // ),
    ];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.2, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: FadeTransition(
        opacity: _animationController,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          itemCount: drawerItems.length,
          itemBuilder: (context, index) {
            final item = drawerItems[index];
            // Staggered animation for each item
            final delay = Duration(milliseconds: 30 * index);
            final itemAnimation = CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                delay.inMilliseconds /
                    _animationController.duration!.inMilliseconds,
                1.0,
                curve: Curves.easeOutCubic,
              ),
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(itemAnimation),
              child: FadeTransition(
                opacity: itemAnimation,
                child: _buildDrawerTile(context, item, index),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),

          // Only show logout button if user is logged in
          if (_isLoggedIn)
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      title: Column(
                        children: const [
                          Icon(
                            Icons.exit_to_app_rounded,
                            size: 30,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Confirm Logout',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      actions: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              245,
                              131,
                              131,
                            ),
                          ),
                          onPressed: () async {
                            await _authStateService.logout();
                            if (mounted) {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Close drawer
                            }
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },

              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),
          Text(
            widget.coreData?.footerCopyright ?? 'POWERED BY GREENCREON',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Version ${AppConfig.appVersion} (Build ${AppConfig.buildNumber})',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(BuildContext context, _DrawerItem item, int index) {
    const Color amberBase = Color(0xFFFFC107);
    const Color amberDark = Color(0xFFFFB300);

    bool isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:
              isHovered
                  ? amberBase.withOpacity(0.1)
                  : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isHovered
                  ? [
                    BoxShadow(
                      color: amberBase.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isHovered ? amberBase : amberBase.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow:
                        isHovered
                            ? [
                              BoxShadow(
                                color: amberBase.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                            : null,
                  ),
                  child: Icon(
                    item.icon,
                    color: isHovered ? Colors.white : amberBase,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isHovered ? FontWeight.w600 : FontWeight.w500,
                      color: isHovered ? amberDark : Colors.black87,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(
                    isHovered ? 5.0 : 0.0,
                    0.0,
                    0.0,
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isHovered ? amberDark : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String title;
  final bool isLogout;
  final VoidCallback? onTap;

  _DrawerItem({
    required this.icon,
    required this.title,
    this.isLogout = false,
    this.onTap,
  });
}
