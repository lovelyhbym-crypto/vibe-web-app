class DashboardModel {
  final double totalSaved;
  final double todaySaved;
  final double weekSaved;
  final Map<String, double> categoryBreakdown;
  final List<double>
  weeklyTrend; // Last 7 days, index 0 is 6 days ago, index 6 is today
  final DateTime? topWishlistPrediction;
  final double? topWishlistRemaining;
  final double averageDailySavings;

  DashboardModel({
    required this.totalSaved,
    required this.todaySaved,
    required this.weekSaved,
    required this.categoryBreakdown,
    required this.weeklyTrend,
    this.topWishlistPrediction,
    this.topWishlistRemaining,
    this.averageDailySavings = 0,
  });

  factory DashboardModel.empty() {
    return DashboardModel(
      totalSaved: 0,
      todaySaved: 0,
      weekSaved: 0,
      categoryBreakdown: {},
      weeklyTrend: List.filled(7, 0.0),
      averageDailySavings: 0,
    );
  }
}
