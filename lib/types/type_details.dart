import 'package:cake_bliss/bloc/type_details/bloc.dart';
import 'package:cake_bliss/bloc/type_details/event.dart';
import 'package:cake_bliss/bloc/type_details/state.dart';
import 'package:cake_bliss/checkout/checkout_cart.dart';
import 'package:cake_bliss/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Changed back to StatefulWidget since the framework is looking for its State
class TypeDetailsPage extends StatefulWidget {
  final String typeId;
  final String categoryName;
  final Map<String, dynamic> typeData;

  const TypeDetailsPage({
    Key? key,
    required this.typeId,
    required this.categoryName,
    required this.typeData,
  }) : super(key: key);

  @override
  State<TypeDetailsPage> createState() => _TypeDetailsPageState();
}

// Added back the state class that the framework is looking for
class _TypeDetailsPageState extends State<TypeDetailsPage> {
  @override
  Widget build(BuildContext context) {
    // Provide the BLoC
    return BlocProvider(
      create: (_) =>
          TypeDetailsBloc()..add(FetchTypeDetailsEvent(widget.typeId)),
      child: TypeDetailsView(
        typeId: widget.typeId,
        categoryName: widget.categoryName,
        initialTypeData: widget.typeData,
      ),
    );
  }
}

class TypeDetailsView extends StatefulWidget {
  final String typeId;
  final String categoryName;
  final Map<String, dynamic> initialTypeData;

  const TypeDetailsView({
    Key? key,
    required this.typeId,
    required this.categoryName,
    required this.initialTypeData,
  }) : super(key: key);

  @override
  State<TypeDetailsView> createState() => _TypeDetailsViewState();
}

class _TypeDetailsViewState extends State<TypeDetailsView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showCustomizationDialog(
      BuildContext context, String selectedWeight, double basePrice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Customize Your Cake',
            style: TextStyle(color: AppColors().mainColor),
          ),
          content: Text(
            'Would you like to create your own cake design for $selectedWeight?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No', style: TextStyle(color: AppColors().mainColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/customization',
                  arguments: {
                    'typeId': widget.typeId,
                    'weight': selectedWeight,
                    'basePrice': basePrice,
                    'typeName': widget.initialTypeData['name'],
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors().mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    return Stack(
      children: [
        Card(
          color: AppColors().subcolor,
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.error_outline,
                              size: 40, color: Colors.red),
                        );
                      },
                    ),
                    // Semi-transparent overlay for better text visibility
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                            Colors.white.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // Image counter
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPage + 1}/${images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSelectionChips(
      BuildContext context, List<dynamic> weights, TypeDetailsLoaded state) {
    return Wrap(
      spacing: 10,
      children: weights.map((weight) {
        return ChoiceChip(
          label: Text(weight.toString()),
          selected: state.selectedWeight == weight,
          onSelected: (bool selected) {
            if (selected) {
              context
                  .read<TypeDetailsBloc>()
                  .add(SelectWeightEvent(weight.toString()));
            }
          },
          backgroundColor: AppColors().mainColor,
          selectedColor: AppColors().subcolor.withOpacity(0.5),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector(BuildContext context, TypeDetailsLoaded state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove_circle_outline, color: AppColors().mainColor),
          onPressed: () {
            if (state.quantity > 1) {
              context.read<TypeDetailsBloc>().add(
                    UpdateQuantityEvent(state.quantity - 1),
                  );
            }
          },
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors().mainColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            state.quantity.toString(),
            style: TextStyle(
              fontSize: 16,
              color: AppColors().mainColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: AppColors().mainColor),
          onPressed: () {
            context.read<TypeDetailsBloc>().add(
                  UpdateQuantityEvent(state.quantity + 1),
                );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TypeDetailsBloc, TypeDetailsState>(
      listener: (context, state) {
        if (state is TypeDetailsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is FavoriteToggleSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.isFavorite
                  ? 'Added to favorites'
                  : 'Removed from favorites'),
              duration: const Duration(seconds: 1),
            ),
          );
        } else if (state is AddToCartSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to cart successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state is AddToCartError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is TypeDetailsInitial || state is TypeDetailsLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is! TypeDetailsLoaded) {
          return const Scaffold(
            body: Center(child: Text('Type not found')),
          );
        }

        final typeData = state.typeData;
        final List<dynamic> images = typeData['images'] ?? [];
        final List<dynamic> weights = typeData['weights'] ?? [];
        final baseRate = double.tryParse(typeData['rate'].toString()) ?? 0.0;

        return Scaffold(
          backgroundColor: AppColors().subcolor,
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (state.selectedWeight == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please select a weight first')),
                        );
                        return;
                      }

                      context.read<TypeDetailsBloc>().add(
                            AddToCartEvent(
                              typeId: widget.typeId,
                              categoryName: widget.categoryName,
                              typeData: typeData,
                              selectedWeight: state.selectedWeight!,
                              quantity: state.quantity,
                              calculatedPrice: state.calculatedPrice,
                            ),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors().mainColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (state.selectedWeight == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please select a weight first')),
                        );
                        return;
                      }

                      // Create the item in the format expected by CheckoutPage
                      final directItem = {
                        'typeId': widget.typeId,
                        'name': typeData['name'],
                        'image': typeData['images'][0],
                        'weight': state.selectedWeight,
                        'price': state.calculatedPrice,
                        'quantity': state.quantity,
                      };

                      // Use MaterialPageRoute to pass the parameter correctly
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CheckoutPage(directCheckoutItem: directItem),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors().subcolor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildImageCarousel(images),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                typeData['name'],
                                style: TextStyle(
                                  fontSize: 24,
                                  color: AppColors().mainColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return ScaleTransition(
                                      scale: animation, child: child);
                                },
                                child: Icon(
                                  state.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  key: ValueKey<bool>(state.isFavorite),
                                  color: state.isFavorite
                                      ? Colors.red
                                      : AppColors().mainColor,
                                  size: 24,
                                ),
                              ),
                              onPressed: () {
                                context.read<TypeDetailsBloc>().add(
                                      ToggleFavoriteEvent(
                                        typeId: widget.typeId,
                                        typeData: typeData,
                                        categoryName: widget.categoryName,
                                      ),
                                    );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 16),
                        Text(
                          '₹${state.calculatedPrice > 0 ? state.calculatedPrice.toStringAsFixed(2) : baseRate.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (state.selectedWeight != null)
                          Text(
                            'for ${state.selectedWeight}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors().mainColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          typeData['description'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Weights',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors().mainColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildWeightSelectionChips(context, weights, state),
                        Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors().mainColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildQuantitySelector(context, state),
                        const SizedBox(
                            height:
                                80), // Space at the bottom for better scrolling
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}
