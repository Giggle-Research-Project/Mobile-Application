import 'package:flutter/material.dart';

class PerformanceAnalysisScreen extends StatelessWidget {
  const PerformanceAnalysisScreen({Key? key}) : super(key: key);

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
          'Performance Analysis',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPerformanceMetricsCard(),
            const SizedBox(height: 20),
            _buildProgressIndicators(),
            const SizedBox(height: 20),
            _buildFutureActivityButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                icon: Icons.timer_outlined,
                title: 'Response Time',
                value: '2.5 sec',
                color: Colors.blue.shade300,
              ),
              _buildMetricItem(
                icon: Icons.track_changes,
                title: 'Accuracy',
                value: '92%',
                color: Colors.green.shade300,
              ),
              _buildMetricItem(
                icon: Icons.gesture,
                title: 'Gesture',
                value: '85%',
                color: Colors.orange.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Progression',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        _buildSingleProgressIndicator(
          title: 'First Attempt',
          progress: 0.6,
          color: Colors.blue.shade300,
        ),
        const SizedBox(height: 15),
        _buildSingleProgressIndicator(
          title: 'Second Attempt',
          progress: 0.8,
          color: Colors.green.shade300,
        ),
        const SizedBox(height: 15),
        _buildSingleProgressIndicator(
          title: 'Third Attempt',
          progress: 0.9,
          color: Colors.orange.shade300,
        ),
      ],
    );
  }

  Widget _buildSingleProgressIndicator({
    required String title,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFutureActivityButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // Navigate to Future Activity Screen
          // Navigator.push(context, MaterialPageRoute(builder: (context) => FutureActivityScreen()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'View Future Activities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
