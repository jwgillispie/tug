// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bevent.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/buttons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load values when screen is initialized
    context.read<ValuesBloc>().add(LoadValues());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<ValuesBloc, ValuesState>(
        builder: (context, state) {
          if (state is ValuesLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is ValuesError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }
          
          if (state is ValuesLoaded) {
            final values = state.values.where((v) => v.active).toList();
            
            if (values.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No values defined yet'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: TugButtons.primaryButtonStyle,
                      onPressed: () {
                        context.go('/values-input');
                      },
                      child: const Text('Add Values'),
                    ),
                  ],
                ),
              );
            }
            
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Your Values',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...values.map((value) {
                  final Color valueColor = Color(
                    int.parse(value.color.substring(1), radix: 16) + 0xFF000000,
                  );
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: valueColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(value.name),
                      subtitle: Text('Importance: ${value.importance}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to value detail screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${value.name} selected'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: TugButtons.secondaryButtonStyle,
                  onPressed: () {
                    context.go('/values-input');
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Values'),
                ),
                
                const Divider(height: 48),
                
                // Feature Cards Section
                const Text(
                  'Features',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Activity Tracking Card
                GestureDetector(
                  onTap: () {
                    context.go('/activities');
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TugColors.primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.history,
                              color: TugColors.primaryPurple,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Activity Tracking',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Log time spent on your values',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Progress Tracking Card (Coming Soon)
                Card(
                  color: Colors.white,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TugColors.secondaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.insights,
                            color: TugColors.secondaryTeal,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Progress Tracking',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coming Soon',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.lock_outline),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          
          return const Center(
            child: Text('No values loaded'),
          );
        },
      ),
    );
  }
}