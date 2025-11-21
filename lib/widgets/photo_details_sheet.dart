import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';

class PhotoDetailsSheet extends StatelessWidget {
  final AssetEntity asset;

  const PhotoDetailsSheet({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Photo Details",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow(
            context,
            icon: Icons.calendar_today_rounded,
            label: "Date Taken",
            value: DateFormat(
              'MMMM d, yyyy • h:mm a',
            ).format(asset.createDateTime),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            icon: Icons.image_rounded,
            label: "Resolution",
            value: "${asset.width} x ${asset.height}",
          ),
          const SizedBox(height: 16),
          FutureBuilder<File?>(
            future: asset.file,
            builder: (context, snapshot) {
              String sizeText = "Calculating...";
              String pathText = "Loading...";

              if (snapshot.hasData && snapshot.data != null) {
                final file = snapshot.data!;
                final sizeInBytes = file.lengthSync();
                final sizeInMB = sizeInBytes / (1024 * 1024);
                sizeText = "${sizeInMB.toStringAsFixed(2)} MB";
                pathText = file.path;
              }

              return Column(
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.data_usage_rounded,
                    label: "File Size",
                    value: sizeText,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    icon: Icons.folder_open_rounded,
                    label: "File Path",
                    value: pathText,
                    isPath: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isPath = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: isPath ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
