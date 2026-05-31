enum AppMode { client, driver, admin, ops }

extension AppModeRouting on AppMode {
	String get routePath {
		switch (this) {
			case AppMode.client:
				return '/';
			case AppMode.driver:
				return '/driver';
			case AppMode.admin:
				return '/admin';
			case AppMode.ops:
				return '/ops-dashboard';
		}
	}

	String get displayLabel {
		switch (this) {
			case AppMode.client:
				return 'Client Mode';
			case AppMode.driver:
				return 'Driver Mode';
			case AppMode.admin:
				return 'Admin Mode';
			case AppMode.ops:
				return 'Ops Dashboard Mode';
		}
	}
}
