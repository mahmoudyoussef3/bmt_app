import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/features/component/presentation/component_demo_app.dart';

void main() {
  registerClientDependencies();
  runApp(const ComponentDemoApp());
}
