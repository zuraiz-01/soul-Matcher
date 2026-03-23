import 'package:flutter/material.dart';
import 'package:soul_matcher/app/core/constants/app_constants.dart';

class PhotoGridPicker extends StatelessWidget {
  const PhotoGridPicker({
    required this.photos,
    required this.onAdd,
    required this.onDelete,
    super.key,
  });

  final List<String> photos;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final int total = AppConstants.maxProfilePhotos;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: total,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (_, int index) {
        if (index < photos.length) {
          final String url = photos[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.network(url, fit: BoxFit.cover),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () => onDelete(url),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardColor,
            ),
            child: const Icon(Icons.add_a_photo_outlined),
          ),
        );
      },
    );
  }
}
