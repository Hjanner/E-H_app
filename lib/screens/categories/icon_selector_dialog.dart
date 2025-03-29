import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class IconSelectorDialog extends StatefulWidget {
  final String currentIcon;
  
  const IconSelectorDialog({Key? key, required this.currentIcon}) : super(key: key);

  @override
  State<IconSelectorDialog> createState() => _IconSelectorDialogState();
}

class _IconSelectorDialogState extends State<IconSelectorDialog> {
  late String _selectedIcon;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.currentIcon;
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar Icono',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchField(),
            const SizedBox(height: 16),
            _buildIconGrid(),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar icono...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildIconGrid() {
    // Lista de iconos comunes para categorías
    final icons = [
      {'icon': Icons.shopping_bag, 'name': 'shopping_bag', 'code': '0xe8a7'},
      {'icon': Icons.shopping_cart, 'name': 'shopping_cart', 'code': '0xe8a8'},
      {'icon': Icons.store, 'name': 'store', 'code': '0xe8d7'},
      {'icon': Icons.category, 'name': 'category', 'code': '0xe148'},
      {'icon': Icons.inventory, 'name': 'inventory', 'code': '0xe179'},
      {'icon': Icons.devices, 'name': 'devices', 'code': '0xe387'},
      {'icon': Icons.phone_android, 'name': 'phone_android', 'code': '0xe324'},
      {'icon': Icons.laptop, 'name': 'laptop', 'code': '0xe31c'},
      {'icon': Icons.headphones, 'name': 'headphones', 'code': '0xe310'},
      {'icon': Icons.camera_alt, 'name': 'camera', 'code': '0xe3af'},
      {'icon': Icons.watch, 'name': 'watch', 'code': '0xe334'},
      {'icon': Icons.tv, 'name': 'tv', 'code': '0xe333'},
      {'icon': Icons.kitchen, 'name': 'kitchen', 'code': '0xe51a'},
      {'icon': Icons.chair, 'name': 'chair', 'code': '0xe30d'},
      {'icon': Icons.lightbulb, 'name': 'lightbulb', 'code': '0xe3a8'},
      {'icon': Icons.vpn_key, 'name': 'key', 'code': '0xe8e2'},
      {'icon': Icons.sports_football, 'name': 'sports', 'code': '0xe57c'},
      {'icon': Icons.brush, 'name': 'brush', 'code': '0xe149'},
      {'icon': Icons.book, 'name': 'book', 'code': '0xe865'},
      {'icon': Icons.bookmark, 'name': 'bookmark', 'code': '0xe866'},
      {'icon': Icons.restaurant, 'name': 'restaurant', 'code': '0xe56c'},
      {'icon': Icons.fastfood, 'name': 'food', 'code': '0xe57a'},
      {'icon': Icons.pets, 'name': 'pets', 'code': '0xe91d'},
      {'icon': Icons.child_care, 'name': 'child', 'code': '0xe577'},
      {'icon': Icons.fitness_center, 'name': 'fitness', 'code': '0xe574'},
      {'icon': Icons.spa, 'name': 'spa', 'code': '0xe57d'},
      {'icon': Icons.medical_services, 'name': 'medical', 'code': '0xe7e5'},
      {'icon': Icons.directions_car, 'name': 'car', 'code': '0xe540'},
      {'icon': Icons.construction, 'name': 'tools', 'code': '0xf8cf'},
      {'icon': Icons.home, 'name': 'home', 'code': '0xe318'},
      {'icon': Icons.celebration, 'name': 'celebration', 'code': '0xe7e9'},
      {'icon': Icons.star, 'name': 'star', 'code': '0xe838'},
      {'icon': Icons.favorite, 'name': 'favorite', 'code': '0xe25b'},
      {'icon': Icons.attach_money, 'name': 'money', 'code': '0xe227'},
      {'icon': Icons.emoji_events, 'name': 'trophy', 'code': '0xe7ef'},
      {'icon': Icons.extension, 'name': 'extension', 'code': '0xe87b'},
    ];
    
    // Filtrar iconos por búsqueda
    final filteredIcons = _searchQuery.isEmpty
        ? icons
        : icons.where((icon) => (icon['name'] as String).contains(_searchQuery)).toList();
    
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredIcons.length,
          itemBuilder: (context, index) {
            final iconData = filteredIcons[index];
            final isSelected = _selectedIcon == (iconData['code'] as String);
            
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedIcon = (iconData['code'] as String);
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primaryColor 
                        : Colors.grey.withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData['icon'] as IconData,
                  size: 32,
                  color: isSelected 
                      ? AppTheme.primaryColor
                      : Colors.grey[600],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIcon),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          child: const Text(
            'Seleccionar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
} 