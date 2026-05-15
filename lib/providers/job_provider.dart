import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';

class JobProvider extends ChangeNotifier {
  List<JobModel> _jobs = [];
  List<CourseModel> _courses = [];

  bool _loadingJobs = false;
  bool _loadingCourses = false;
  bool _hasMoreJobs = true;
  int _jobPage = 1;
  int _coursePage = 1;

  String _jobSearch = '';

  List<JobModel> get jobs => _jobs;
  List<CourseModel> get courses => _courses;
  bool get loadingJobs => _loadingJobs;
  bool get loadingCourses => _loadingCourses;
  bool get hasMoreJobs => _hasMoreJobs;

  Future<void> fetchJobs({bool refresh = false}) async {
    if (_loadingJobs) return;
    if (refresh) {
      _jobPage = 1;
      _hasMoreJobs = true;
      _jobs = [];
    }
    if (!_hasMoreJobs) return;

    _loadingJobs = true;
    notifyListeners();

    try {
      final data = await apiService.getJobs(
        search: _jobSearch.isEmpty ? null : _jobSearch,
        page: _jobPage,
      );
      final items = (data['data'] as List).map((e) => JobModel.fromJson(e)).toList();
      _jobs = refresh ? items : [..._jobs, ...items];
      _hasMoreJobs = data['next_page_url'] != null;
      _jobPage++;
    } catch (_) {}

    _loadingJobs = false;
    notifyListeners();
  }

  Future<void> fetchCourses({bool refresh = false}) async {
    if (_loadingCourses) return;
    if (refresh) {
      _coursePage = 1;
      _courses = [];
    }

    _loadingCourses = true;
    notifyListeners();

    try {
      final data = await apiService.getCourses(page: _coursePage);
      final items = (data['data'] as List).map((e) => CourseModel.fromJson(e)).toList();
      _courses = refresh ? items : [..._courses, ...items];
      _coursePage++;
    } catch (_) {}

    _loadingCourses = false;
    notifyListeners();
  }

  void setJobSearch(String q) {
    _jobSearch = q;
    fetchJobs(refresh: true);
  }
}
