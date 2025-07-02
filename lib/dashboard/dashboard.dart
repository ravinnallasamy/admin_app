import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/login/login_screen.dart';
import 'package:app/pages/patients/patients_page.dart';
import 'package:app/pages/profile_settings.dart';
import 'package:app/pages/notification_settings.dart';
import 'package:app/pages/security_page.dart';
import 'package:app/pages/help_support.dart';
import 'package:app/pages/about_page.dart';

class Dashboard extends StatefulWidget {
  final String email;
  final Function(String) onPasswordChanged;

  const Dashboard({
    super.key,
    required this.email,
    required this.onPasswordChanged,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;
  int _patientCount = 0;
  String _doctorName = ''; // To store doctor's name

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
    try {
      // Fetch patient's count
      final response = await Supabase.instance.client
          .from('patients')
          .select('id'); // Assuming each patient has a unique id

      // Fetch doctor's name from the 'admin_auth' table based on the logged-in email
      final userResponse = await Supabase.instance.client
          .from('admin_auth')
          .select('name')
          .eq('email', widget.email)
          .single();

      setState(() {
        _patientCount = response.length;
        // Fetch the name from the response
        if (userResponse != null) {
          _doctorName = userResponse['name'];
        }
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Set the current time as the logout time
              final logoutTime = DateTime.now().toIso8601String();

              try {
                // Update the logout time in the 'admin_auth' table
                await Supabase.instance.client
                    .from('admin_auth')
                    .update({'logout_time': logoutTime})
                    .eq('email', widget.email);

                // Clear shared preferences (if needed)
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('email');
                await prefs.remove('login_time');

                // Close the dialog
                Navigator.pop(context);

                // Navigate back to the login screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              } catch (e) {
                // Handle error
                debugPrint('Error logging out: $e');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    return switch (_currentIndex) {
      0 => _buildDashboardScreen(),
      1 => const PatientsPage(),
      2 => _buildSettingsScreen(),
      _ => _buildDashboardScreen(),
    };
  }

  Widget _buildDashboardScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.medical_services, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              'Welcome, $_doctorName!', // Show doctor's name here
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800]),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _buildDashboardCard(
                  icon: Icons.people,
                  title: 'Patients',
                  count: '$_patientCount',
                  color: Colors.blue,
                ),
                _buildDashboardCard(
                  icon: Icons.calendar_today,
                  title: 'Appointments',
                  count: '',
                  color: Colors.green,
                ),
                _buildDashboardCard(
                  icon: Icons.medication,
                  title: 'Prescriptions',
                  count: '',
                  color: Colors.orange,
                ),
                _buildDashboardCard(
                  icon: Icons.notifications,
                  title: 'Alerts',
                  count: '',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            if (count.isNotEmpty)
              Text(count, style: TextStyle(fontSize: 24, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile Settings'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notification Settings'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const NotificationSettingsPage()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Security'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecurityPage()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Help & Support'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpSupportPage()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutPage()),
          ),
        ),
      ],
    );
  }
}
