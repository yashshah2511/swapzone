import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool isLoading = true;
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    final res = await ApiService.getAnalytics();
    if (res['success'] == true) {
      setState(() {
        data = res['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load analytics")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7))),
      );
    }

    final monthlySales = List<double>.from(
      (data['monthlySales'] ?? List.filled(12, 0)).map((e) => e.toDouble()),
    );

    final maxValue = monthlySales.isNotEmpty
        ? monthlySales.reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Admin Analytics",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00C9A7),
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header Section
            const SizedBox(height: 10),
            const Text(
              "Dashboard Overview",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Summary Cards
            Row(
              children: [
                _buildCard(
                  "Total Users",
                  data['totalUsers'].toString(),
                  Icons.people,
                  const Color(0xFF00C9A7),
                ),
                const SizedBox(width: 14),
                _buildCard(
                  "Products",
                  data['totalProducts'].toString(),
                  Icons.shopping_bag,
                  Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildCard(
                  "Orders",
                  data['totalOrders'].toString(),
                  Icons.shopping_cart,
                  Colors.purpleAccent,
                ),
                const SizedBox(width: 14),
                _buildCard(
                  "Revenue",
                  "₹${data['totalRevenue']}",
                  Icons.currency_rupee,
                  Colors.teal,
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 🔹 Chart Title
            const Center(
              child: Text(
                "Monthly Revenue Overview",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 🔹 Bar Chart
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: BarChart(
                  BarChartData(
                    maxY: maxValue * 1.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: Colors.grey[300], strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          interval: maxValue > 0 ? maxValue / 5 : 1,
                          getTitlesWidget: (val, meta) => Text(
                            "₹${val.toInt()}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const months = [
                              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                months[value.toInt() % 12],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Color(0xFF00C9A7),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: monthlySales.asMap().entries.map((entry) {
                      final index = entry.key;
                      final val = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: val,
                            color: const Color(0xFF00C9A7),
                            width: 18,
                            borderRadius: BorderRadius.circular(6),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxValue * 1.2,
                              color: Colors.grey[200],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Center(
              child: Text(
                "📊 SwapZone Admin Panel",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              offset: const Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
