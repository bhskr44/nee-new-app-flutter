import '../widgets/app_search_field.dart';
import '../widgets/app_empty_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_model.dart';
import '../models/course_model.dart';
import '../providers/job_provider.dart';
import '../services/activity_service.dart';
import '../services/api_service.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _searchCtrl.text = context.read<JobProvider>().jobSearch;
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder:
          (context, prov, _) => Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              title: const Text('Jobs & Training'),
              bottom: TabBar(
                controller: _tab,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [Tab(text: 'Find Jobs'), Tab(text: 'Training')],
              ),
            ),
            body: TabBarView(
              controller: _tab,
              children: [
                _JobsTab(prov: prov, searchCtrl: _searchCtrl),
                _CoursesTab(prov: prov),
              ],
            ),
          ),
    );
  }
}

// ─── Jobs Tab ─────────────────────────────────────────────────────────────────

class _JobsTab extends StatelessWidget {
  final JobProvider prov;
  final TextEditingController searchCtrl;

  const _JobsTab({required this.prov, required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppSearchField(
            controller: searchCtrl,
            hint: 'Search jobs or companies',
            onChanged: prov.setJobSearch,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => prov.fetchJobs(refresh: true),
            child:
                prov.jobs.isEmpty && prov.loadingJobs
                    ? const Center(child: CircularProgressIndicator())
                    : prov.jobs.isEmpty
                    ? AppEmptyState(
                      icon: Icons.work_outline,
                      title:
                          prov.jobsError != null
                              ? 'Could not load jobs'
                              : 'No jobs found',
                      message:
                          prov.jobsError ??
                          'Try a different role or company name.',
                      actionLabel: 'Refresh jobs',
                      onAction: () => prov.fetchJobs(refresh: true),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: prov.jobs.length + (prov.hasMoreJobs ? 1 : 0),
                      itemBuilder:
                          (_, i) =>
                              i < prov.jobs.length
                                  ? _JobCard(job: prov.jobs[i])
                                  : Center(
                                    child:
                                        prov.loadingJobs
                                            ? const CircularProgressIndicator()
                                            : TextButton(
                                              onPressed: () => prov.fetchJobs(),
                                              child: Text(
                                                prov.jobsError != null
                                                    ? 'Try loading more again'
                                                    : 'Load more jobs',
                                              ),
                                            ),
                                  ),
                    ),
          ),
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _apply(context),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57F17).withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Color(0xFFF57F17),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        job.company,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57F17).withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    job.jobTypeLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFF57F17),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 13, color: Colors.grey),
                Text(
                  job.location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                if (job.minSalary != null)
                  Text(
                    job.maxSalary != null
                        ? '₹${_fmt(job.minSalary!)} – ₹${_fmt(job.maxSalary!)}'
                        : '₹${_fmt(job.minSalary!)}+',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            if (job.requirements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    job.requirements
                        .take(3)
                        .map(
                          (r) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              r,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _apply(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57F17),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Apply Now', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  void _apply(BuildContext context) {
    activityService.log(
      'apply_job',
      entityType: 'job',
      entityId: job.id,
      entityName: job.title,
      extra: {'company': job.company, 'location': job.location},
    );

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool submitting = false;
    PlatformFile? pickedCv;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setModalState) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply — ${job.title}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.company,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number *',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Experience / Cover Note',
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (pickedCv != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.description,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                pickedCv!.name,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setModalState(() => pickedCv = null),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'doc', 'docx'],
                              withData: true,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              setModalState(
                                () => pickedCv = result.files.first,
                              );
                            }
                          },
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Attach CV (optional)'),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              submitting
                                  ? null
                                  : () async {
                                    if (nameCtrl.text.trim().isEmpty ||
                                        phoneCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter your name and mobile number',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setModalState(() => submitting = true);
                                    try {
                                      await apiService.applyJob(job.id, {
                                        'full_name': nameCtrl.text.trim(),
                                        'phone': phoneCtrl.text.trim(),
                                        'cover_note': noteCtrl.text.trim(),
                                      }, cv: pickedCv);
                                      if (!ctx.mounted) return;
                                      Navigator.pop(ctx);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Application submitted! ${job.company} will contact you.',
                                            ),
                                            backgroundColor: Colors.green[700],
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (_) {
                                      setModalState(() => submitting = false);
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Submission failed. Please try again.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF57F17),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              submitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Submit Application',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}

// ─── Courses Tab ───────────────────────────────────────────────────────────────

class _CoursesTab extends StatelessWidget {
  final JobProvider prov;
  const _CoursesTab({required this.prov});

  @override
  Widget build(BuildContext context) {
    if (prov.courses.isEmpty && prov.loadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.courses.isEmpty) {
      return AppEmptyState(
        icon: Icons.school_outlined,
        title:
            prov.coursesError != null
                ? 'Could not load training'
                : 'No training courses yet',
        message:
            prov.coursesError ?? 'New courses will appear here when available.',
        actionLabel: 'Refresh courses',
        onAction: () => prov.fetchCourses(refresh: true),
      );
    }
    return RefreshIndicator(
      onRefresh: () => prov.fetchCourses(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: prov.courses.length,
        itemBuilder: (_, i) => _CourseCard(course: prov.courses[i]),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final modeColor = switch (course.mode) {
      'online' => const Color(0xFF2E7D32),
      'hybrid' => const Color(0xFF1565C0),
      _ => const Color(0xFFF57F17),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _enroll(context),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57F17).withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Color(0xFFF57F17),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        course.provider,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: modeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    course.mode[0].toUpperCase() + course.mode.substring(1),
                    style: TextStyle(
                      fontSize: 10,
                      color: modeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  course.duration,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 12),
                if (course.certification != null) ...[
                  const Icon(
                    Icons.verified_outlined,
                    size: 13,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.certification!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                Text(
                  course.fee == 0
                      ? 'Free'
                      : '₹${course.fee.toStringAsFixed(0)}',
                  style: TextStyle(
                    color:
                        course.fee == 0
                            ? Colors.green[700]
                            : const Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (course.description != null) ...[
              const SizedBox(height: 6),
              Text(
                course.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _enroll(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57F17),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Apply Now', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _enroll(BuildContext context) async {
    activityService.log(
      'apply_course',
      entityType: 'course',
      entityId: course.id,
      entityName: course.name,
      extra: {'provider': course.provider, 'mode': course.mode},
    );

    final url = course.applyUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Applications for this course are not open yet'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the application form')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
