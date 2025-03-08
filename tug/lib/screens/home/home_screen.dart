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
                const Text(
                  'Coming soon: Activity tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TugColors.lightSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TugColors.primaryPurple.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track your daily activities and see how they align with your values.',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This feature is under development and will be available soon.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: TugColors.lightTextSecondary,
                        ),
                      ),
                    ],
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