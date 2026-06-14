import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';
import 'package:bmt_app/core/widgets/app_button.dart';

class SupportRefundRequestScreen extends StatefulWidget {
  const SupportRefundRequestScreen({super.key});

  @override
  State<SupportRefundRequestScreen> createState() => _SupportRefundRequestScreenState();
}

class _SupportRefundRequestScreenState extends State<SupportRefundRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedReason;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  
  File? _evidenceFile;

  final List<String> _reasons = [
    'Trip Canceled by Driver',
    'Bus Did Not Arrive',
    'Double Charged',
    'App Error',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
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
        _evidenceFile = File(result.files.single.path!);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedReason != null) {
      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      
      context.read<SupportCubit>().createRefundRequest(
        reason: _selectedReason!,
        description: _descController.text.trim(),
        amount: amount,
        evidenceFile: _evidenceFile,
      );
    } else if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for refund'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Request Refund',
          style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: BlocConsumer<SupportCubit, SupportState>(
        listener: (context, state) {
          if (state is SupportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else if (state is SupportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Refund requests typically take 3-5 business days to process after approval.',
                          style: TextStyle(color: Colors.blue[900], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Refund',
                    border: OutlineInputBorder(),
                  ),
                  items: _reasons.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedReason = val);
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Refund Amount (EGP)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Amount is required';
                    final amount = double.tryParse(val.trim());
                    if (amount == null || amount <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Details (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                
                // Evidence
                InkWell(
                  onTap: _pickAttachment,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _evidenceFile != null 
                                ? _evidenceFile!.path.split('/').last 
                                : 'Attach receipt or screenshot (Optional)',
                            style: TextStyle(color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_evidenceFile != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _evidenceFile = null),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                AppButton.primary(
                  text: isLoading ? 'Submitting Request...' : 'Submit Refund Request',
                  onPressed: isLoading ? () {} : _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
