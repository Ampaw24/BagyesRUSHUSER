// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/foundation.dart';
import '../core/utils/config..utils.dart';

/// Returns the appropriate base URL depending on the build mode.
/// In debug mode the DEV_BASE_URL is used; in release/profile the PROD_BASE_URL.
String get BASEURL => kDebugMode ? Config.devBaseUrl : Config.baseUrl;