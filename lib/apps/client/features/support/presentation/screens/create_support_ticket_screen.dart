import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

class CreateSupportTicketScreen extends StatefulWidget {
  final String? initialCategory;

  const CreateSupportTicketScreen({super.key, this.initialCategory});

  @override
  State<CreateSupportTicketScreen> createState() =>
      _CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState extends State<CreateSupportTicketScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedCategory;
  String _selectedPriority = 'low';
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  File? _attachment;

  final List<String> _categories = [
    'Booking Issue',
    'Payment Issue',
    'Trip Delay',
    'Driver or Vehicle Issue',
    'Subscription Issue',
    'Lost Item',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Other';
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'Other';
    }
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
      allowedExtensions: ['jpg', 'png', 'pdf', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachment = File(result.files.single.path!);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<SupportCubit>().createTicket(
        category: _selectedCategory,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _selectedPriority,
        attachment: _attachment,
      );
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: ClientTypography.bodyMedium(context).copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ClientTypography.bodyMedium(context).copyWith(
          color: scheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withAlpha(50),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withAlpha(80)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'New Ticket',
          style: ClientTypography.headingSmall(context).copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        centerTitle: true,
      ),
      body: BlocConsumer<SupportCubit, SupportState>(
        listener: (context, state) {
          if (state is SupportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Ticket created successfully!'),
                backgroundColor: scheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            Navigator.pop(context);
            if (state.ticket != null) {
              Navigator.pushNamed(
                context,
                '/ticket_details',
                arguments: state.ticket!.id,
              );
            }
          } else if (state is SupportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is SupportActionLoading;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'What is your issue about?',
                  style: ClientTypography.headingSmall(context).copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: scheme.primary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest.withAlpha(50),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: scheme.outlineVariant.withAlpha(80)),
                    ),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        cat,
                        style: ClientTypography.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Priority Level',
                  style: ClientTypography.headingSmall(context).copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: ['low', 'medium', 'high'].map((priority) {
                    final isSelected = _selectedPriority == priority;
                    return ChoiceChip(
                      label: Text(priority.toUpperCase()),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedPriority = priority);
                      },
                      labelStyle: ClientTypography.labelMedium(context).copyWith(
                        color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                      selectedColor: scheme.primary,
                      backgroundColor: scheme.surfaceContainerHighest.withAlpha(50),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? scheme.primary : scheme.outlineVariant.withAlpha(50),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  'Ticket Title',
                  _titleController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Title is required';
                    if (val.trim().length < 5) return 'Title too short';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Description',
                  _descController,
                  maxLines: 5,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Description is required';
                    if (val.trim().length < 10) return 'Please provide more details';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Attachments',
                  style: ClientTypography.headingSmall(context).copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickAttachment,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: _attachment != null ? scheme.primary.withAlpha(15) : scheme.surfaceContainerHighest.withAlpha(30),
                      border: Border.all(
                        color: _attachment != null ? scheme.primary.withAlpha(80) : scheme.outlineVariant.withAlpha(80),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.shadow.withAlpha(10),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _attachment != null ? Icons.file_present_rounded : Icons.cloud_upload_rounded,
                            color: _attachment != null ? scheme.primary : scheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _attachment != null
                                    ? _attachment!.path.split('/').last
                                    : 'Upload Image or Document',
                                style: ClientTypography.bodyMedium(context).copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_attachment == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'JPG, PNG, or PDF up to 5MB',
                                    style: ClientTypography.bodySmall(context).copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_attachment != null)
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: scheme.error),
                            onPressed: () => setState(() => _attachment = null),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                ClientButton(
                  label: isLoading ? 'Submitting...' : 'Submit Ticket',
                  isLoading: isLoading,
                  expand: true,
                  onPressed: isLoading ? () {} : _submit,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
