import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/ide_provider.dart';

class MarketplacePane extends StatefulWidget {
  const MarketplacePane({Key? key}) : super(key: key);

  @override
  State<MarketplacePane> createState() => _MarketplacePaneState();
}

class _MarketplacePaneState extends State<MarketplacePane> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);
    final extensions = provider.marketplaceExtensions;

    return Container(
      color: provider.editorBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF151517),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.storefront, color: provider.neonCyanColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "EXTENSION MARKETPLACE",
                      style: GoogleFonts.outfit(
                        color: provider.textPrimaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: () => provider.fetchMarketplaceExtensions(),
                  tooltip: "Refresh extensions",
                  style: IconButton.styleFrom(
                    foregroundColor: provider.neonCyanColor,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main extensions grid
          Expanded(
            child: extensions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: provider.neonCyanColor),
                        const SizedBox(height: 12),
                        Text(
                          "Loading extensions...",
                          style: GoogleFonts.outfit(
                            color: provider.textSecondaryColor,
                            fontSize: 11,
                          ),
                        )
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: extensions.length,
                    itemBuilder: (context, index) {
                      final ext = extensions[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: provider.cardBgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: provider.borderColor, width: 0.5),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ext.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          color: provider.neonCyanColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ext.version,
                                      style: TextStyle(
                                        color: provider.textSecondaryColor,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "by ${ext.publisher}",
                                  style: TextStyle(
                                    color: provider.textSecondaryColor,
                                    fontSize: 9,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  ext.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: provider.textPrimaryColor,
                                    fontSize: 10,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 10),
                                    const SizedBox(width: 2),
                                    Text(
                                      ext.rating.toString(),
                                      style: TextStyle(fontSize: 9, color: provider.textPrimaryColor),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.download, color: provider.textSecondaryColor, size: 10),
                                    const SizedBox(width: 2),
                                    Text(
                                      "${(ext.downloads / 1000).toStringAsFixed(0)}k",
                                      style: TextStyle(fontSize: 9, color: provider.textSecondaryColor),
                                    ),
                                  ],
                                ),
                                if (ext.isInstalling)
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: provider.neonCyanColor,
                                    ),
                                  )
                                else if (ext.isInstalled)
                                  ElevatedButton(
                                    onPressed: () => provider.uninstallExtension(ext),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: provider.neonPinkColor.withOpacity(0.15),
                                      foregroundColor: provider.neonPinkColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        side: BorderSide(color: provider.neonPinkColor, width: 0.5),
                                      ),
                                    ),
                                    child: const Text("UNINSTALL", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () => provider.installExtension(ext),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: provider.neonGreenColor.withOpacity(0.15),
                                      foregroundColor: provider.neonGreenColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        side: BorderSide(color: provider.neonGreenColor, width: 0.5),
                                      ),
                                    ),
                                    child: const Text("INSTALL", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
