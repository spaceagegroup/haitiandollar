import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../models/wallet_state.dart';

class LoanPaymentResult {
  final double htdAmount;
  final String mfiName;
  final String mfiWallet;
  final String loanId;

  LoanPaymentResult({
    required this.htdAmount,
    required this.mfiName,
    required this.mfiWallet,
    required this.loanId,
  });
}

Future<LoanPaymentResult?> showLoanSheet(
  BuildContext context, {
  required double maxBalance,
}) async {
  double amount = 30.0;
  String loanId = '';
  MfiConfig selectedMfi = WalletState.availableMfis.first;

  return showModalBottomSheet<LoanPaymentResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final grossHtg = amount * WalletState.invariantRate;
        final bool valid =
            amount > 0 &&
            amount <= maxBalance &&
            loanId.trim().isNotEmpty &&
            selectedMfi.activeAddress.isNotEmpty;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Microfinance Loan Repayment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Direct settlement to participating institutional wallet',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(height: 16),

              // 1. MFI Selector Dropdown
              DropdownButtonFormField<MfiConfig>(
                initialValue: selectedMfi,
                decoration: const InputDecoration(
                  labelText: 'Participating Institution',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.landmark, size: 18),
                ),
                dropdownColor: const Color(0xFF1E1E1E),
                items: WalletState.availableMfis.map((mfi) {
                  return DropdownMenuItem<MfiConfig>(
                    value: mfi,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            mfi.name,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!mfi.isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Testnet',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedMfi = val);
                },
              ),

              const SizedBox(height: 12),

              // 2. Loan / Borrower Contract Number
              TextFormField(
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Loan Account # / Borrower ID',
                  hintText: 'e.g. FKZ-8821-09',
                  prefixIcon: const Icon(LucideIcons.hash, size: 18),
                  errorText: loanId.isNotEmpty && loanId.trim().isEmpty
                      ? 'Loan ID required'
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) => setModalState(() => loanId = val),
              ),

              const SizedBox(height: 12),

              // 3. Amount Field
              TextFormField(
                initialValue: '30',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Repayment Amount (HTD)',
                  prefixText: 'H\$ ',
                  border: const OutlineInputBorder(),
                  suffixText: 'Max: ${maxBalance.toStringAsFixed(2)}',
                ),
                onChanged: (val) =>
                    setModalState(() => amount = double.tryParse(val) ?? 0.0),
              ),

              const SizedBox(height: 14),

              // 4. Invariant Confirmation Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Principal Credited (5:1):',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    Text(
                      '${grossHtg.toStringAsFixed(2)} HTG',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFCC419),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 5. Submit Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCC419),
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: valid
                    ? () => Navigator.pop(
                        ctx,
                        LoanPaymentResult(
                          htdAmount: amount,
                          mfiName: selectedMfi.name,
                          mfiWallet: selectedMfi.activeAddress,
                          loanId: loanId.trim(),
                        ),
                      )
                    : null,
                child: Text(
                  loanId.trim().isEmpty
                      ? 'Enter Loan ID'
                      : amount > maxBalance
                      ? 'Insufficient Balance'
                      : 'Submit Repayment of H\$ ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
