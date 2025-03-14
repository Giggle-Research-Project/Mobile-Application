import 'package:flutter/material.dart';
import 'package:giggle/features/overall_performance/widgets/FutureActivityButton.dart';
import 'package:giggle/features/overall_performance/widgets/PerformanceCards.dart';
import 'package:giggle/features/overall_performance/widgets/PerformanceOverviewCard.dart';
import 'package:giggle/features/overall_performance/widgets/PerformancePieChart.dart';

class OverallPerformanceScreen extends StatelessWidget {
  const OverallPerformanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Performance',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///* Performance Overview Card
            PerformanceOverviewCard(),
            SizedBox(height: 20),

            ///* Performance Pie Chart
            PerformancePieChart(),
            SizedBox(height: 20),

            ///* Performance Cards
            PerformanceCards(),
            SizedBox(height: 20),

            ///* Future Activity Button
            FutureActivityButton(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
