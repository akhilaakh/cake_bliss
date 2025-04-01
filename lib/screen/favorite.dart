import 'package:cake_bliss/bloc/favourite/bloc.dart';
import 'package:cake_bliss/bloc/favourite/event.dart';
import 'package:cake_bliss/bloc/favourite/state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cake_bliss/types/type_details.dart';
import 'package:cake_bliss/constants/app_colors.dart';

class FavouritePage extends StatelessWidget {
  const FavouritePage({Key? key}) : super(key: key);

  void navigateToTypeDetails(
      BuildContext context, Map<String, dynamic> cakeData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TypeDetailsPage(
          typeId: cakeData['typeId'],
          categoryName: cakeData['categoryName'],
          typeData: cakeData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FavouriteBloc()..add(LoadFavorites()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Favorites'),
          backgroundColor: AppColors().mainColor,
        ),
        body: BlocBuilder<FavouriteBloc, FavouriteState>(
          builder: (context, state) {
            if (state is FavouriteLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is FavouriteError) {
              return Center(child: Text(state.message));
            } else if (state is FavouriteLoaded) {
              return _buildFavoritesGrid(context, state.favorites);
            } else {
              return const Center(child: Text('Unknown state'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildFavoritesGrid(
      BuildContext context, List<QueryDocumentSnapshot> favorites) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final doc = favorites[index];
          final data = doc.data() as Map<String, dynamic>;

          return GestureDetector(
            onTap: () => navigateToTypeDetails(context, data),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cake Image
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            image: DecorationImage(
                              image: NetworkImage(data['image'] ?? ''),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                context.read<FavouriteBloc>().add(
                                      RemoveFavorite(docId: doc.id),
                                    );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cake Details
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Category: ${data['categoryName'] ?? ''}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Text(
                            '₹${data['price']?.toString() ?? '0'}',
                            style: TextStyle(
                              color: AppColors().mainColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
