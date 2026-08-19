import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/related_booking_option.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_category.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_office_option.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'support_attachment_picker.dart';
import 'support_category_dropdown.dart';
import 'support_field_label.dart';
import 'support_office_dropdown.dart';
import 'support_related_booking_dropdown.dart';
import 'support_text_field.dart';

/// The create-ticket form: topic, subject, details, optional attachment.
/// Clients don't set a priority — support triages that on the dashboard.
class CreateTicketForm extends StatefulWidget {
  const CreateTicketForm({super.key, required this.isSubmitting});

  final bool isSubmitting;

  @override
  State<CreateTicketForm> createState() => _CreateTicketFormState();
}

class _CreateTicketFormState extends State<CreateTicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _category = defaultSupportCategory;
  SupportOfficeOption? _office;
  RelatedBookingOption? _relatedBooking;
  File? _attachment;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SupportCubit>();
    cubit.loadRelatedBookingOptions();
    cubit.loadOfficeOptions();
  }

  /// The office the complaint is filed against.
  ///
  /// A linked booking decides it: the backend derives the ticket's office from
  /// the booking's trip and overrides whatever the form sends, so the picker
  /// shows that office rather than pretending the choice is still open. Only
  /// when nothing is linked (or the operating office isn't one the client can
  /// see) does their own pick apply — implicitly when there is a single office,
  /// since asking a question with one answer helps nobody.
  SupportOfficeOption? _effectiveOffice(List<SupportOfficeOption> options) {
    final bookingOffice = _bookingOffice(options);
    if (bookingOffice != null) return bookingOffice;
    if (_office != null) return _office;
    return options.length == 1 ? options.first : null;
  }

  /// The office that operated the linked booking, when it is one of the offices
  /// the client can see. An unlisted operator has no name to show, so the
  /// picker stays open there — the server still routes the ticket to the trip's
  /// office either way.
  SupportOfficeOption? _bookingOffice(List<SupportOfficeOption> options) {
    final officeId = _relatedBooking?.officeId;
    if (officeId == null) return null;
    for (final option in options) {
      if (option.id == officeId) return option;
    }
    return null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    final path = result?.files.single.path;
    if (path == null || !mounted) return;
    setState(() => _attachment = File(path));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<SupportCubit>();
    final office = _effectiveOffice(cubit.officeOptions);

    cubit.createTicket(
      category: _category,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      officeId: office?.id,
      relatedBookingId: _relatedBooking?.bookingId,
      relatedTripId: _relatedBooking?.tripId,
      attachment: _attachment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportCubit>();
    final bookingOptions = cubit.relatedBookingOptions;
    final officeOptions = cubit.officeOptions;

    final bookingOffice = _bookingOffice(officeOptions);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          SupportFieldLabel(
            label: context.l10n.support_topicLabel,
            hint: context.l10n.support_topicHint,
          ),
          SupportCategoryDropdown(
            value: _category,
            onChanged: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: 24),
          SupportFieldLabel(
            label: context.l10n.support_officeLabel,
            hint: bookingOffice == null
                ? context.l10n.support_officeHint
                : context.l10n.support_officeFromBookingHint,
            isRequired: true,
          ),
          SupportOfficeDropdown(
            options: officeOptions,
            value: _effectiveOffice(officeOptions),
            onChanged: (office) => setState(() => _office = office),
            hasError: cubit.officeLoadFailed,
            onRetry: cubit.loadOfficeOptions,
            isLocked: bookingOffice != null,
          ),
          const SizedBox(height: 24),

          if (bookingOptions.isNotEmpty) ...[
            SupportFieldLabel(
              label: context.l10n.support_relatedBookingLabel,
              hint: context.l10n.support_relatedBookingHint,
            ),
            SupportRelatedBookingDropdown(
              options: bookingOptions,
              value: _relatedBooking,
              onChanged: (option) => setState(() => _relatedBooking = option),
            ),
            const SizedBox(height: 24),
          ],
          SupportTextField(
            label: context.l10n.support_subjectLabel,
            labelHint: context.l10n.support_subjectHint,
            controller: _titleController,
            hint: context.l10n.support_subjectPlaceholder,
            emptyMessage: context.l10n.support_subjectRequired,
            minLength: 5,
          ),
          const SizedBox(height: 24),
          SupportTextField(
            label: context.l10n.support_detailsLabel,
            labelHint: context.l10n.support_detailsHint,
            controller: _descController,
            hint: context.l10n.support_detailsPlaceholder,
            emptyMessage: context.l10n.support_detailsRequired,
            minLength: 10,
            maxLines: 6,
          ),
          const SizedBox(height: 24),
          SupportFieldLabel(
            label: context.l10n.support_attachmentLabel,
            hint: context.l10n.support_attachmentHint,
          ),
          SupportAttachmentPicker(
            attachment: _attachment,
            onPick: _pickAttachment,
            onClear: () => setState(() => _attachment = null),
          ),
          const SizedBox(height: 40),
          ClientButton(
            label: widget.isSubmitting
                ? context.l10n.support_submitting
                : context.l10n.support_submitTicket,
            isLoading: widget.isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
