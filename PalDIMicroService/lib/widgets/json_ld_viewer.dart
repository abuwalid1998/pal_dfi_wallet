import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/models/verifiable_credential.dart';
import '../theme/app_theme.dart';

class JsonLdViewer extends StatelessWidget {
  final VerifiableCredential credential;

  const JsonLdViewer({
    super.key,
    required this.credential,
  });

  @override
  Widget build(BuildContext context) {
    final prettyJson = credential.toPrettyJsonString();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.obsidianBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slateCardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.charcoalDark,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.slateCardBorder),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.navyPrimary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.goldPrimary, width: 0.8),
                  ),
                  child: Text(
                    'W3C VC 2.0 • JSON-LD',
                    style: GoogleFonts.robotoMono(
                      color: AppColors.goldPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  color: AppColors.goldPrimary,
                  tooltip: 'Copy Payload',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: prettyJson));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('W3C VC JSON-LD copied to clipboard'),
                        backgroundColor: AppColors.navyPrimary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.goldPrimary),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Code Display Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                prettyJson,
                style: GoogleFonts.firaCode(
                  color: const Color(0xFFE2E8F0),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
