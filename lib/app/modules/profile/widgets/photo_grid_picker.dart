import 'package:flutter/material.dart';
import 'package:soul_matcher/app/core/constants/app_constants.dart';

class PhotoGridPicker extends StatelessWidget {
  const PhotoGridPicker({
    required this.photos,
    required this.onAdd,
    required this.onDelete,
    this.isBusy = false,
    super.key,
  });

  final List<String> photos;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final int total = AppConstants.maxProfilePhotos;
    final ThemeData theme = Theme.of(context);
    final Color borderColor = theme.dividerColor.withValues(alpha: 0.4);
    final Color fillColor = theme.colorScheme.surface.withValues(alpha: 0.7);

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
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Photo ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: isBusy ? null : () => onDelete(url),
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
          onTap: isBusy ? null : onAdd,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: fillColor,
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  ),
                  child: isBusy
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.add_a_photo_outlined,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  isBusy
                      ? 'Uploading...'
                      : index == 0
                      ? 'Add cover'
                      : 'Add photo',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
