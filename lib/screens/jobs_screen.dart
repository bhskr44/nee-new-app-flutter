import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<Job> get _filteredJobs => mockJobs
      .where((j) => _search.isEmpty || j.title.toLowerCase().contains(_search.toLowerCase()) || j.company.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Jobs & Training'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Find Jobs'), Tab(text: 'Training Programs')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _JobsTab(jobs: _filteredJobs, search: _search, onSearch: (v) => setState(() => _search = v)),
          const _TrainingTab(),
        ],
      ),
    );
  }
}

class _JobsTab extends StatelessWidget {
  final List<Job> jobs;
  final String search;
  final ValueChanged<String> onSearch;

  const _JobsTab({required this.jobs, required this.search, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search jobs, companies...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              fillColor: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text('${jobs.length} jobs found', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list, size: 16),
              label: const Text('Filter', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFF57F17)),
            ),
          ]),
        ),
        Expanded(
          child: jobs.isEmpty
              ? const Center(child: Text('No jobs found'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) => _JobCard(job: jobs[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&h=240&fit=crop&auto=format',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFE65100)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xD8E65100), Color(0xC0F57F17)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(children: [
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Build Your Career',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Top construction companies hiring now',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('8 Jobs',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
                Text('Active listings',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  const _JobCard({required this.job});

  static const _jobImage = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&h=180&fit=crop&auto=format';
  static const _jobColor = Color(0xFFF57F17);

  @override
  Widget build(BuildContext context) {
    final isContract = job.jobType.contains('Contract');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _jobImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: Color(0xFFE65100)),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x50E65100), Color(0xD0BF360C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 10, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isContract ? Colors.orange.shade700 : Colors.green.shade700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isContract ? 'Contract' : 'Full-time',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10, left: 14, right: 14,
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.business_center, color: _jobColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(job.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(job.company,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.location_on, size: 13, color: Colors.grey),
              const SizedBox(width: 3),
              Text(job.location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(width: 12),
              const Icon(Icons.currency_rupee, size: 13, color: Colors.grey),
              Text('${job.minSalary} – ${job.maxSalary}/mo', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
              const SizedBox(width: 3),
              Text('Apply by ${job.deadline}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            Text(job.description, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: job.requirements.take(3).map((r) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                child: Text(r, style: const TextStyle(fontSize: 11)),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showDetail(context),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF57F17),
                      side: const BorderSide(color: Color(0xFFF57F17)),
                      padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('View Details', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showApply(context),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('Apply Now', style: TextStyle(fontSize: 13)),
                ),
              ),
            ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(job.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(job.company, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 12),
            Text(job.description, style: TextStyle(color: Colors.grey[700], height: 1.5)),
            const SizedBox(height: 14),
            const Text('Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...job.requirements.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFFE65100)),
                const SizedBox(width: 8),
                Expanded(child: Text(r, style: const TextStyle(fontSize: 13))),
              ]),
            )),
            const SizedBox(height: 14),
            _row('Location', job.location),
            _row('Salary', '${job.minSalary} – ${job.maxSalary}/month'),
            _row('Type', job.jobType),
            _row('Last Date', job.deadline),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); _showApply(context); },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Apply for This Job'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 80, child: Text(l, style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
    ]),
  );

  void _showApply(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apply — ${job.title}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(job.company, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 10),
            const TextField(keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Mobile Number')),
            const SizedBox(height: 10),
            const TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email Address')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Years of Experience')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Current Location')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Application sent to ${job.company}!'), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Submit Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingTab extends StatelessWidget {
  const _TrainingTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildTrainingHeader(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Available Courses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...mockCourses.map((c) => _CourseCard(course: c)),
      ],
    );
  }

  Widget _buildTrainingHeader() {
    return SizedBox(
      height: 140,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&h=280&fit=crop&auto=format',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF1565C0)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xCC1565C0), Color(0xDD1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Skill Up, Earn More',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Government-certified courses\nfrom ₹2,500. Learn & earn.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                Row(children: [
                  _pill('NSDC Certified'),
                  const SizedBox(width: 8),
                  _pill('ITI Approved'),
                  const SizedBox(width: 8),
                  _pill('Online + Offline'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withAlpha(35), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final TrainingCourse course;
  const _CourseCard({required this.course});

  static const _courseImages = {
    'Mason Training': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=600&h=180&fit=crop&auto=format',
    'Electrical Wiring': 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=600&h=180&fit=crop&auto=format',
    'Plumbing Basics': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&h=180&fit=crop&auto=format',
    'AutoCAD for Construction': 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600&h=180&fit=crop&auto=format',
    'Site Safety': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&h=180&fit=crop&auto=format',
    'Interior Design': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=600&h=180&fit=crop&auto=format',
    'False Ceiling Work': 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=600&h=180&fit=crop&auto=format',
    'Welding': 'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=600&h=180&fit=crop&auto=format',
  };

  static const _accentColor = Color(0xFF1565C0);

  String get _imageUrl =>
      _courseImages[course.name] ??
      'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=600&h=180&fit=crop&auto=format';

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: Color(0xFF1565C0)),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accentColor.withValues(alpha: 0.25),
                        _accentColor.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 10, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '₹${course.fee.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10, left: 14, right: 14,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(course.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(course.provider,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.description,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 13, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _chip(Icons.schedule, course.duration, Colors.orange),
                  _chip(Icons.verified, course.certification, Colors.green),
                  _chip(Icons.place, course.mode.split(' — ').first, Colors.blue),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showEnroll(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 10)),
                    child: const Text('Enrol Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _showEnroll(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Enrol in ${course.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Provider: ${course.provider}'),
          Text('Duration: ${course.duration}'),
          Text('Mode: ${course.mode}'),
          Text('Fee: ₹${course.fee.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          Text('Certification: ${course.certification}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Enrolled in ${course.name}!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Confirm Enrolment'),
          ),
        ],
      ),
    );
  }
}
