// lib/widgets/home/components/mobile_home_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/values/bloc/values_bloc.dart';
import '../../../blocs/values/bloc/values_event.dart';
import '../../../blocs/activities/activities_bloc.dart';
import '../../../blocs/vices/bloc/vices_bloc.dart';
import '../../../blocs/vices/bloc/vices_event.dart';
import '../../../utils/mobile_ux_utils.dart';
import '../../../utils/theme/colors.dart';
import '../../../services/app_mode_service.dart';

class MobileHomeWrapper extends StatelessWidget {
  final Widget child;
  final AppMode currentMode;
  
  const MobileHomeWrapper({
    super.key,
    required this.child,
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = currentMode == AppMode.vicesMode;
    
    return Semantics(
      label: 'Home screen, pull down to refresh',
      child: MobileUXUtils.pullToRefresh(
        onRefresh: () => _refreshData(context),
        color: TugColors.getPrimaryColor(isViceMode),
        child: MobileUXUtils.keyboardAwareScroll(
          padding: EdgeInsets.only(
            bottom: MobileUXUtils.getThumbFriendlyPosition(context) * 0.1,
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _refreshData(BuildContext context) async {
    // Refresh data based on current mode
    if (currentMode == AppMode.vicesMode) {
      context.read<VicesBloc>().add(const LoadVices());
    } else {
      context.read<ValuesBloc>().add(const LoadValues(forceRefresh: true));
      context.read<ActivitiesBloc>().add(const LoadActivities(forceRefresh: true));
    }
    
    // Small delay to show refresh indicator
    await Future.delayed(const Duration(milliseconds: 500));
  }
}