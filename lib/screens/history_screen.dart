import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/scan_provider.dart';
import '../models/scan_history_model.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showFavoritesOnly = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Consumer<ScanProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 14),
                        Text('Reports', style: AppTextStyles.heading(size: 18)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                          child: Icon(
                            _showFavoritesOnly ? Icons.star : Icons.star_border,
                            color: _showFavoritesOnly ? AppColors.neonAmber : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        if (provider.history.isNotEmpty)
                          GestureDetector(
                            onTap: () => _confirmClearAll(context, provider),
                            child: const Icon(Icons.delete_sweep_outlined,
                                color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                              style: AppTextStyles.body(size: 13),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search by plant or disease name...',
                                hintStyle: AppTextStyles.body(size: 12, color: AppColors.textSecondary),
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        var list = _showFavoritesOnly
                            ? provider.history.where((s) => s.isFavorite).toList()
                            : provider.history;

                        if (_searchQuery.isNotEmpty) {
                          list = list.where((s) {
                            return s.plantName.toLowerCase().contains(_searchQuery) ||
                                s.diseaseName.toLowerCase().contains(_searchQuery);
                          }).toList();
                        }

                        if (list.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty
                                      ? Icons.search_off
                                      : _showFavoritesOnly
                                      ? Icons.star_border
                                      : Icons.history,
                                  size: 60,
                                  color: AppColors.textSecondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No matches found'
                                      : _showFavoritesOnly
                                      ? 'No favorites yet'
                                      : 'No scans yet',
                                  style: AppTextStyles.body(color: AppColors.textSecondary, size: 14),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            return _HistoryTile(
                              item: item,
                              onDelete: () => provider.deleteHistoryItem(item),
                              onToggleFavorite: () => provider.toggleFavorite(item),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, ScanProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDark2,
        title: Text('Clear all history?', style: AppTextStyles.heading(size: 16)),
        content: Text('This action cannot be undone.',
            style: AppTextStyles.body(size: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.body(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(ctx);
            },
            child: Text('Clear', style: AppTextStyles.body(color: AppColors.neonRed)),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ScanHistoryModel item;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _HistoryTile({
    required this.item,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(item.scannedAt);
    final statusColor = item.isHealthy ? AppColors.neonGreen : AppColors.neonRed;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.neonRed.withOpacity(0.25),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.neonRed),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: File(item.imagePath).existsSync()
                    ? Image.file(File(item.imagePath), width: 60, height: 60, fit: BoxFit.cover)
                    : Container(
                  width: 60,
                  height: 60,
                  color: Colors.white.withOpacity(0.05),
                  child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.plantName, style: AppTextStyles.heading(size: 14)),
                    const SizedBox(height: 4),
                    Text(
                      item.isHealthy ? 'Healthy' : item.diseaseName,
                      style: AppTextStyles.body(size: 12, color: statusColor),
                    ),
                    const SizedBox(height: 4),
                    Text(formattedDate,
                        style: AppTextStyles.body(size: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggleFavorite,
                child: Icon(
                  item.isFavorite ? Icons.star : Icons.star_border,
                  color: item.isFavorite ? AppColors.neonAmber : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}