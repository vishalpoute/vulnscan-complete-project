import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vulnscan/config/constants/app_constants.dart';
import 'package:vulnscan/services/http_client_service.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final _userEmailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _upgradeUser(String tier) async {
    final email = _userEmailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('❌ Enter user email', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final httpClient = HttpClientService();
      final encodedEmail = Uri.encodeComponent(email);
      final url = '${AppConstants.baseApiUrl}/api/admin/upgrade-user?user_email=$encodedEmail&tier=$tier';
      
      print('🔄 Upgrade request to: $url');
      
      final response = await httpClient.dio.post(url);

      if (response.statusCode == 200) {
        _showSnackBar('✅ User upgraded to $tier successfully!', Colors.green);
        _userEmailController.clear();
        print('✅ Upgrade successful: ${response.data}');
      } else {
        print('Full response: ${response.data}');
        String errorMsg = 'Unknown error (${response.statusCode})';
        
        // Handle different error formats
        if (response.data is Map) {
          if (response.data['detail'] != null) {
            errorMsg = response.data['detail'].toString();
          } else if (response.data['message'] != null) {
            errorMsg = response.data['message'].toString();
          }
        }
        
        _showSnackBar('❌ Error: $errorMsg', Colors.red);
        print('❌ Upgrade failed: $errorMsg (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Upgrade error: $e');
      String errorMessage = e.toString();
      if (e.toString().contains('404')) {
        errorMessage = 'User not found in database';
      } else if (e.toString().contains('Connection')) {
        errorMessage = 'Cannot connect to server. Make sure backend is running on port 8000';
      }
      _showSnackBar('❌ Error: $errorMessage', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetUserScans() async {
    final email = _userEmailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('❌ Enter user email', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final httpClient = HttpClientService();
      final encodedEmail = Uri.encodeComponent(email);
      final url = '${AppConstants.baseApiUrl}/api/admin/reset-scans?user_email=$encodedEmail';
      
      print('🔄 Reset scans request to: $url');
      
      final response = await httpClient.dio.post(url);

      if (response.statusCode == 200) {
        _showSnackBar('✅ Scans reset to 0 successfully!', Colors.green);
        _userEmailController.clear();
        print('✅ Reset successful: ${response.data}');
      } else {
        print('Full response: ${response.data}');
        String errorMsg = 'Unknown error (${response.statusCode})';
        
        // Handle different error formats
        if (response.data is Map) {
          if (response.data['detail'] != null) {
            errorMsg = response.data['detail'].toString();
          } else if (response.data['message'] != null) {
            errorMsg = response.data['message'].toString();
          }
        }
        
        _showSnackBar('❌ Error: $errorMsg', Colors.red);
        print('❌ Reset failed: $errorMsg (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Reset scans error: $e');
      String errorMessage = e.toString();
      if (e.toString().contains('404')) {
        errorMessage = 'User not found in database';
      } else if (e.toString().contains('Connection')) {
        errorMessage = 'Cannot connect to server. Make sure backend is running on port 8000';
      }
      _showSnackBar('❌ Error: $errorMessage', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _testBackendConnection() async {
    setState(() => _isLoading = true);
    
    try {
      final httpClient = HttpClientService();
      final url = '${AppConstants.baseApiUrl}/api/health/diagnostic';
      
      print('🔍 Testing backend connection: $url');
      final response = await httpClient.dio.get(url);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final mongoStatus = data['mongodb']?['status'] ?? 'Unknown';
        final userCount = data['mongodb']?['users_in_database'] ?? 0;
        final fsStatus = data['firestore']?['status'] ?? 'Unknown';
        
        final message = '''
✅ BACKEND CONNECTED!
━━━━━━━━━━━━━━━━━━
MongoDB: $mongoStatus
Users in DB: $userCount
Firestore: $fsStatus
        ''';
        
        _showSnackBar(message, Colors.green);
        print('✅ Backend diagnostic: $data');
      }
    } catch (e) {
      print('❌ Backend connection error: $e');
      String errorMessage = e.toString();
      if (errorMessage.contains('Connection refused')) {
        errorMessage = '❌ Backend not running!\nStart: python -m uvicorn main:app --reload --port 8000';
      } else if (errorMessage.contains('Failed host lookup')) {
        errorMessage = '❌ Cannot reach localhost:8000\nCheck if backend is running';
      }
      _showSnackBar(errorMessage, Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _userEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ Admin Panel'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'User Management',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // Email Input
            TextField(
              controller: _userEmailController,
              decoration: InputDecoration(
                hintText: 'Enter user email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              readOnly: _isLoading,
            ),
            const SizedBox(height: 24),

            // Diagnostic Button
            Text(
              'Diagnostics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testBackendConnection,
                icon: const Icon(Icons.health_and_safety),
                label: const Text('🔍 Test Backend Connection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.teal,
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upgrade Buttons
            Text(
              'Upgrade Plan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _upgradeUser('pro'),
                    icon: const Icon(Icons.star),
                    label: const Text('Pro'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _upgradeUser('enterprise'),
                    icon: const Icon(Icons.business),
                    label: const Text('Enterprise'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.purple,
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reset Scans Button
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _resetUserScans,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Scans to 0'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.orange,
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text('Processing...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
