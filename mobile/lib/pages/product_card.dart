 import 'package:flutter/material.dart';
import 'package:mobile/services/api_client.dart'; // Убедитесь, что путь верный для Product
class ProductGridCard extends StatelessWidget {
  final Product product;
  final int inCart;
  final VoidCallback onAddToCart;
  final VoidCallback? onRemoveFromCart;

  final List<int> linkedSupplierIds;
  final Future<void> Function(int supplierId) onRequestLink;

  const ProductGridCard({
    Key? key,
    required this.product,
    required this.inCart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onRequestLink,
    required this.linkedSupplierIds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final supplierId = product.supplierId;
    final supplierName = product.supplierName ?? 'Supplier #$supplierId';

    final isLinked = linkedSupplierIds.contains(supplierId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
            ),
            ),

            const SizedBox(height: 8),

            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),

            Text(
              supplierName,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),

            const Spacer(),

            if (isLinked) ...[
              // SHOW PRICE
              Text(
                '${(product.price ?? 0).toStringAsFixed(2)} ₸',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (inCart > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: onRemoveFromCart,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text('$inCart', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: onAddToCart,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                )
              else
                _buildAddButton(theme),
            ] else ...[
              const Text(
                'Price hidden',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 4),
              _buildConnectButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onPressed: onAddToCart,
        child: const Text('Add to Cart'),
      ),
    );
  }

  Widget _buildConnectButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () => onRequestLink(product.supplierId),
        child: const Text('Connect'),
      ),
    );
  }
}
