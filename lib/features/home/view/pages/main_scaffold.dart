import 'dart:io';

import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:rajakumari_scheme/core/api_secrets/api_secrets.dart';
import 'package:rajakumari_scheme/core/config/app_config.dart';
import 'package:rajakumari_scheme/core/controllers/coredata_controller.dart';
import 'package:rajakumari_scheme/core/controllers/store_list_controller.dart';
import 'package:rajakumari_scheme/core/global_widgets/custom_alert_box.dart';

import 'package:rajakumari_scheme/core/models/coredata_model.dart';
import 'package:rajakumari_scheme/core/services/auth_state_service.dart';
import 'package:rajakumari_scheme/features/authentication/view/pages/login_with_phone_page.dart';
import 'package:rajakumari_scheme/features/home/services/update_onesignal_id_service.dart';
import 'package:rajakumari_scheme/features/home/view/pages/home_page.dart';
import 'package:rajakumari_scheme/features/home/view/widgets/app_drawer_widget.dart';
import 'package:rajakumari_scheme/features/passbook/view/pages/passbook_page.dart';
import 'package:rajakumari_scheme/features/profile/view/pages/profile_page.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CoreDataController _coreDataController = CoreDataController();
  final StoreListController _storeListController = StoreListController();

  // final UserDetailsController _userDetailsController = UserDetailsController();
  final AuthStateService _authStateService = AuthStateService();
  CoreData? _coreData;
  bool _isLoading = true;
  String? _error;
  int _httpStatusCode = 200;
  bool _isLoggedIn = false;
  bool _inMaintenance = false;
  @override
  void initState() {
    super.initState();
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppState();
    });
    // Initialize app state
  }

  Future<void> _initializeAppState() async {
    await _checkLoginStatus();
    // Load core data first since other operations might depend on it
    await _loadCoreData();
    // Then load other data in parallel

    await _storeListController.fetchStoreList();
    _authStateService.addListener(_onAuthStateChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from background
    if (state == AppLifecycleState.resumed) {
      // Refresh login status
      _authStateService.refreshAuthState();
      setState(() {
        _isLoggedIn = _authStateService.isLoggedIn;
      });

      _storeListController
          .fetchStoreList(); // Refresh store list when app resumes
    }
  }

  @override
  void dispose() {
    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Remove auth state listener
    _authStateService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    setState(() {
      _isLoggedIn = _authStateService.isLoggedIn;
    });
  }

  // Check initial login status
  Future<void> _checkLoginStatus() async {
    // Force refresh from SharedPreferences
    await _authStateService.refreshAuthState();

    setState(() {
      _isLoggedIn = _authStateService.isLoggedIn;
    });
  }

  // Load core data from the API
  Future<void> _loadCoreData() async {
    try {
      final coreDataResponse = await _coreDataController.getCoreData();

      setState(() {
        _coreData = coreDataResponse.data.first;

        _httpStatusCode = coreDataResponse.httpStatusCode; // HTTP code
        _inMaintenance = coreDataResponse.data.first.inMaintenance == '1';
        _isLoading = false;
      });

      ApiSecrets.setOnesignalAppId(coreDataResponse.data.first.onesignalId);

      // Initialize OneSignal
      if (Platform.isAndroid || Platform.isIOS) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.initialize(coreDataResponse.data.first.onesignalId);

        if (Platform.isAndroid) {
          OneSignal.Notifications.requestPermission(true);
        } else {
          OneSignal.Notifications.requestPermission(false);
        }

        final isLoggedIn = _authStateService.isLoggedIn;
        final userId = _authStateService.userId;

        if (isLoggedIn && userId.isNotEmpty) {
          final externalId = userId.toString();
          await OneSignal.login(externalId);
          await Future.delayed(const Duration(seconds: 2));

          final playerId = await OneSignal.User.getOnesignalId();
          if (playerId != null) {
            UpdateOneSignalIdService().updateOneSignalId(
              externalIid: externalId,
              userId: userId,
              playerId: playerId,
            );
          }
        }
      }
    } catch (e) {
      if (e is Map<String, dynamic>) {
        setState(() {
          _httpStatusCode = e['code'] ?? -1; // API's own code
          _httpStatusCode = e['httpStatusCode'] ?? -1; // HTTP status
          _error = e['data'] ?? e['message'] ?? 'Unknown error';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      // Open drawer when More is tapped
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Method to allow drawer to set the current tab index
  void setCurrentIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMaintenanceScreen({
    required Color color,
    required Widget imageWidget,
    String? message,
    String? estimatedRestore,
    required VoidCallback? onclik,
    required int? httpStatusCode, // Add httpStatusCode parameter
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              imageWidget,
              const SizedBox(height: 30),
              Text(
                httpStatusCode == 426 ? 'Update Required' : 'Maintenance Mode',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                httpStatusCode == 426
                    ? 'A new version of the app is available. Please update to continue.'
                    : message ??
                        'We are currently performing scheduled maintenance.\nPlease check back later.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (estimatedRestore != null && httpStatusCode != 426) ...[
                const SizedBox(height: 12),
                Text(
                  'Estimated completion: $estimatedRestore',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 40),
              if (httpStatusCode == 426)
                _UpdateButton() // Show update button for 426 status
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onclik,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Again'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: Image.asset('assets/images/loading.gif')),
      );
    }
    if (_inMaintenance ||
        _error != null ||
        _storeListController.error != null) {
      return _buildMaintenanceScreen(
        message: _error,
        estimatedRestore: "Few minutes",
        color: Colors.orange,
        imageWidget: Icon(
          _httpStatusCode == 426 ? Icons.system_update : Icons.cloud_queue,
          size: 100,
          color: Colors.orange,
        ),
        onclik: () {
          _authStateService.refreshAuthState();
        },
        httpStatusCode: _httpStatusCode, // Pass the status code
      );
    }
    if (_authStateService.erorr.isNotEmpty &&
        _authStateService.userId.isNotEmpty &&
        _authStateService.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              Text(_authStateService.erorr, textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        contentPadding: const EdgeInsets.fromLTRB(
                          24,
                          0,
                          24,
                          24,
                        ),
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
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginWithPhonePage(),
                                  ),
                                  (route) =>
                                      false, // This removes all previous routes
                                );
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

                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final List<Widget> pages = [
      HomePage(coreData: _coreData),
      PassbookPage(coreData: _coreData),
      _authStateService.isLoggedIn && _authStateService.userId.isNotEmpty
          ? const ProfilePage()
          : LoginWithPhonePage(coreData: _coreData!),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(index: _selectedIndex, children: pages),
      endDrawer: AppDrawerWidget(
        onSelectPassbook: () => setCurrentIndex(1),
        onSelectProfile: () => setCurrentIndex(2),
        coreData: _coreData,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex < 3 ? _selectedIndex : 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.black38,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(FeatherIcons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(FeatherIcons.book),
            label: 'Passbook',
          ),
          BottomNavigationBarItem(
            icon:
                _authStateService.isLoggedIn &&
                        _authStateService.userId.isNotEmpty
                    ? const Icon(FeatherIcons.user)
                    : const Icon(FeatherIcons.logIn),
            label:
                _authStateService.isLoggedIn &&
                        _authStateService.userId.isNotEmpty
                    ? 'Profile'
                    : 'Login',
          ),
          const BottomNavigationBarItem(
            icon: Icon(FeatherIcons.moreHorizontal),
            label: 'More',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}

class _UpdateButton extends StatefulWidget {
  const _UpdateButton();

  @override
  State<_UpdateButton> createState() => _UpdateButtonState();
}

class _UpdateButtonState extends State<_UpdateButton> {
  bool _isUpdating = false;
  AppUpdateResult? _updateResult;

  Future<void> _checkForUpdate() async {
    setState(() => _isUpdating = true);

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        final result = await InAppUpdate.performImmediateUpdate();

        setState(() => _updateResult = result);

        if (result != AppUpdateResult.success) {
          // If in-app update fails, open Play Store
          _openAppStore();
        }
      } else {
        // If no update found via in-app update, open Play Store
        _openAppStore();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: ${e.toString()}')));
      // Fallback to Play Store
      _openAppStore();
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _openAppStore() async {
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=${AppConfig.applicationId}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Play Store')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.amberAccent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isUpdating ? null : _checkForUpdate,
          icon:
              _isUpdating
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Icon(Icons.system_update),
          label: Text(
            _isUpdating ? 'Updating...' : 'Update Now',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        if (_updateResult == AppUpdateResult.inAppUpdateFailed)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'In-app update failed. Redirecting to Play Store...',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
