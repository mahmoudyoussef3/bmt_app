/// The console's shared form kit.
///
/// Every operational create/edit surface — driver, vehicle, trip, route —
/// draws its fields, sections, progress and error recovery from here, so the
/// forms that run the business behave identically wherever an operator meets
/// them.
library;

export 'dashboard_form_controller.dart';
export 'dashboard_form_feedback.dart';
export 'dashboard_form_field.dart';
export 'dashboard_form_section.dart';
