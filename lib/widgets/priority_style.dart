import 'package:flutter/material.dart';

import '../models/task.dart';

Color priorityColor(Priority priority, ColorScheme scheme) =>
    switch (priority) {
      Priority.high => scheme.error,
      Priority.medium => scheme.tertiary,
      Priority.low => scheme.outline,
    };
