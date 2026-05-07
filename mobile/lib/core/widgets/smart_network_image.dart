import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/settings/presentation/bloc/settings_cubit.dart';

class SmartNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SmartNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Only watch isLowDataMode
    final isLowData = context.select((SettingsCubit c) => c.state.isLowDataMode);

    if (isLowData) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
              const SizedBox(height: 4),
              Text(
                "Image masquée",
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              TextButton(
                 onPressed: () {
                   // Logic to load single image override could go here
                   // For now, simpler: user must disable mode settings
                 }, 
                 child: const Text("Charger", style: TextStyle(fontSize: 10))
              )
            ],
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(color: Colors.grey.shade200),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
