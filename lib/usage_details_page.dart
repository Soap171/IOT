import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class UsageDetailsPage extends StatelessWidget {
  const UsageDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Usage Details',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color.fromARGB(255, 3, 48, 86),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDeviceUsageCard(
              title: 'Fan Usage',
              data: [
                BarChartGroupData(x: 0, barRods: [
                  BarChartRodData(toY: 45, color: Colors.blue),
                  BarChartRodData(toY: 38, color: Colors.green)
                ]),
              ],
              devices: ['Fan 1', 'Fan 2'],
            ),
            const SizedBox(height: 20),
            _buildDeviceUsageCard(
              title: 'Bulb Usage',
              data: [
                BarChartGroupData(x: 0, barRods: [
                  BarChartRodData(toY: 60, color: Colors.orange),
                  BarChartRodData(toY: 52, color: Colors.purple)
                ]),
              ],
              devices: ['Bulb 1', 'Bulb 2'],
            ),
            const SizedBox(height: 20),
            _buildSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceUsageCard({
    required String title,
    required List<BarChartGroupData> data,
    required List<String> devices,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: data,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            devices[value.toInt()],
                            style: GoogleFonts.poppins(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Usage Summary',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Fan Usage',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    Text('Hours Used: 83', style: GoogleFonts.poppins()),
                    Text('Energy Consumed: 41.5 kWh',
                        style: GoogleFonts.poppins()),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Bulb Usage',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    Text('Hours Used: 112', style: GoogleFonts.poppins()),
                    Text('Energy Consumed: 16.8 kWh',
                        style: GoogleFonts.poppins()),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
