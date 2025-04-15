// import 'dart:ui';
// import 'package:cakebliss_admin/category/category_screen/edit_category.dart';
// import 'package:cakebliss_admin/constants/appcolor.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'package:flutter/material.dart';

// class TypeDetailsPage extends StatefulWidget {
//   final String typeId;
//   final String categoryName;

//   const TypeDetailsPage({
//     Key? key,
//     required this.typeId,
//     required this.categoryName,
//     required Map<String, dynamic> typeData,
//   }) : super(key: key);

//   @override
//   State<TypeDetailsPage> createState() => _TypeDetailsPageState();
// }

// class _TypeDetailsPageState extends State<TypeDetailsPage> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;
//   bool _isLoading = true;
//   Map<String, dynamic>? _typeData;
//   String? _selectedWeight;
//   double _calculatedPrice = 0.0;
//   double _baseRate = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     _fetchTypeData();
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchTypeData() async {
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('types')
//           .doc(widget.typeId)
//           .get();

//       if (doc.exists) {
//         setState(() {
//           _typeData = doc.data() as Map<String, dynamic>;
//           _isLoading = false;
//           _baseRate = double.tryParse(_typeData!['rate'].toString()) ?? 0.0;
//         });
//       }
//     } catch (e) {
//       print('Error fetching type data: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   void _calculatePrice(String weight) {
//     double weightValue =
//         double.tryParse(weight.replaceAll('kg', '').trim()) ?? 0.0;
//     double baseRate = double.tryParse(_typeData!['rate'].toString()) ?? 0.0;

//     setState(() {
//       _selectedWeight = weight;
//       _calculatedPrice = baseRate * weightValue;
//     });
//   }

//   void _navigateToEditPage() {
//     if (_typeData != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => EditTypePage(
//             typeId: widget.typeId,
//             typeData: _typeData!,
//             onUpdate: () {
//               _fetchTypeData();
//             },
//           ),
//         ),
//       );
//     }
//   }

//   Future<void> _deleteType() async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('types')
//           .doc(widget.typeId)
//           .delete();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Type deleted successfully')),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting type: $e')),
//       );
//     }
//   }

//   void _showDeleteConfirmationDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Delete Confirmation'),
//           content: const Text('Are you sure you want to delete this type?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _deleteType();
//               },
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.red,
//               ),
//               child: const Text('Delete'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(color: AppColors().mainColor),
//               SizedBox(height: 16),
//               Text(
//                 'Loading details...',
//                 style: TextStyle(color: AppColors().mainColor),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     if (_typeData == null) {
//       return Scaffold(
//         appBar: AppBar(
//           backgroundColor: AppColors().mainColor,
//           title: Text('Cake Details'),
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.error_outline, size: 48, color: AppColors().mainColor),
//               SizedBox(height: 16),
//               Text(
//                 'Cake type not found',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 8),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: Text('Go Back'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors().mainColor,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final List<dynamic> images = _typeData!['images'] ?? [];
//     final List<dynamic> weights = _typeData!['weights'] ?? [];

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Image carousel with curved bottom edge
//             _buildImageCarousel(images),

//             // Content section
//             Expanded(
//               child: ClipRRect(
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(30),
//                   topRight: Radius.circular(30),
//                 ),
//                 child: Container(
//                   color: Colors.white,
//                   child: SingleChildScrollView(
//                     physics: BouncingScrollPhysics(),
//                     child: Padding(
//                       padding: EdgeInsets.all(24),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Title and action buttons
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     // Text(
//                                     //   widget.categoryName,
//                                     //   style: TextStyle(
//                                     //     fontSize: 14,
//                                     //     fontWeight: FontWeight.w500,
//                                     //     color: Colors.grey[600],
//                                     //   ),
//                                     // ),
//                                     SizedBox(height: 4),
//                                     Text(
//                                       _typeData!['name'],
//                                       style: TextStyle(
//                                         fontSize: 26,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Row(
//                                 children: [
//                                   _buildActionButton(
//                                     icon: Icons.edit,
//                                     color: AppColors().mainColor,
//                                     backgroundColor:
//                                         Colors.deepPurple.withOpacity(0.1),
//                                     onTap: _navigateToEditPage,
//                                   ),
//                                   SizedBox(width: 8),
//                                   _buildActionButton(
//                                     icon: Icons.delete,
//                                     color: AppColors().mainColor,
//                                     backgroundColor:
//                                         Colors.deepPurple.withOpacity(0.1),
//                                     onTap: _showDeleteConfirmationDialog,
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),

//                           SizedBox(height: 24),

//                           // Price section with beautiful card
//                           _buildPriceCard(),

//                           SizedBox(height: 24),

//                           // Description section
//                           _buildSectionTitle('Description'),
//                           SizedBox(height: 12),
//                           Text(
//                             _typeData!['description'],
//                             style: TextStyle(
//                               fontSize: 16,
//                               height: 1.5,
//                               color: Colors.black87,
//                             ),
//                           ),

//                           SizedBox(height: 24),

//                           // Weight selection
//                           _buildSectionTitle('Select Weight'),
//                           SizedBox(height: 16),
//                           _buildWeightSelector(weights),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildImageCarousel(List<dynamic> images) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.35,
//       width: double.infinity,
//       child: Stack(
//         children: [
//           // Image PageView
//           PageView.builder(
//             controller: _pageController,
//             itemCount: images.length,
//             onPageChanged: (index) {
//               setState(() => _currentPage = index);
//             },
//             itemBuilder: (context, index) {
//               return Container(
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                 ),
//                 child: Image.network(
//                   images[index],
//                   fit: BoxFit.cover,
//                   loadingBuilder: (context, child, loadingProgress) {
//                     if (loadingProgress == null) return child;
//                     return Center(
//                       child: CircularProgressIndicator(
//                         color: AppColors().mainColor,
//                         value: loadingProgress.expectedTotalBytes != null
//                             ? loadingProgress.cumulativeBytesLoaded /
//                                 loadingProgress.expectedTotalBytes!
//                             : null,
//                       ),
//                     );
//                   },
//                   errorBuilder: (context, error, stackTrace) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.image_not_supported,
//                               color: Colors.grey[400], size: 48),
//                           SizedBox(height: 8),
//                           Text('Image not available',
//                               style: TextStyle(color: Colors.grey[600])),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           ),

//           // Back button with blur background
//           Positioned(
//             top: 16,
//             left: 16,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(30),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
//                 child: Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   child: IconButton(
//                     icon: Icon(Icons.arrow_back, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                     constraints: BoxConstraints.tightFor(width: 24, height: 24),
//                     padding: EdgeInsets.zero,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // Page indicators
//           Positioned(
//             bottom: 20,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(
//                 images.length,
//                 (index) => AnimatedContainer(
//                   duration: Duration(milliseconds: 200),
//                   margin: EdgeInsets.symmetric(horizontal: 3),
//                   width: _currentPage == index ? 20 : 8,
//                   height: 8,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(4),
//                     color: _currentPage == index
//                         ? AppColors().mainColor
//                         : Colors.white.withOpacity(0.7),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required Color backgroundColor,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Icon(
//           icon,
//           color: color,
//           size: 20,
//         ),
//       ),
//     );
//   }

//   Widget _buildPriceCard() {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [AppColors().mainColor, AppColors().subcolor],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors().mainColor.withOpacity(0.3),
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Price',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.white.withOpacity(0.8),
//             ),
//           ),
//           SizedBox(height: 8),
//           Row(
//             children: [
//               Text(
//                 '₹',
//                 style: TextStyle(
//                   fontSize: 22,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(width: 4),
//               Text(
//                 '${_calculatedPrice > 0 ? _calculatedPrice.toStringAsFixed(0) : _baseRate.toStringAsFixed(0)}',
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               if (_selectedWeight != null) ...[
//                 SizedBox(width: 8),
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     _selectedWeight!,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.white,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//           if (_calculatedPrice == 0)
//             Text(
//               'Base rate per kg',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.white.withOpacity(0.8),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Row(
//       children: [
//         Container(
//           width: 4,
//           height: 20,
//           decoration: BoxDecoration(
//             color: AppColors().mainColor,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         SizedBox(width: 8),
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildWeightSelector(List<dynamic> weights) {
//     return Container(
//       width: double.infinity,
//       child: Wrap(
//         spacing: 12,
//         runSpacing: 12,
//         children: weights.map((weight) {
//           final bool isSelected = _selectedWeight == weight;
//           return AnimatedContainer(
//             duration: Duration(milliseconds: 200),
//             width: 60,
//             height: 40,
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: () => _calculatePrice(weight.toString()),
//                 borderRadius: BorderRadius.circular(12),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: isSelected ? AppColors().mainColor : Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: isSelected
//                           ? AppColors().mainColor
//                           : Colors.grey[300]!,
//                       width: isSelected ? 0 : 1,
//                     ),
//                     boxShadow: isSelected
//                         ? [
//                             BoxShadow(
//                               color: AppColors().mainColor.withOpacity(0.3),
//                               blurRadius: 8,
//                               offset: Offset(0, 4),
//                             ),
//                           ]
//                         : null,
//                   ),
//                   child: Center(
//                     child: Text(
//                       weight.toString(),
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: isSelected ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

import 'dart:ui';
import 'package:cakebliss_admin/bloc/details_category/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cakebliss_admin/category/category_screen/edit_category.dart';
import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the BLoC related files

class TypeDetailsPage extends StatefulWidget {
  final String typeId;
  final String categoryName;

  const TypeDetailsPage({
    Key? key,
    required this.typeId,
    required this.categoryName,
    required Map<String, dynamic> typeData,
  }) : super(key: key);

  @override
  State<TypeDetailsPage> createState() => _TypeDetailsPageState();
}

class _TypeDetailsPageState extends State<TypeDetailsPage> {
  final PageController _pageController = PageController();
  late TypeDetailsBloc _typeDetailsBloc;

  @override
  void initState() {
    super.initState();
    _typeDetailsBloc = TypeDetailsBloc();
    _typeDetailsBloc.add(FetchTypeDetails(widget.typeId));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _typeDetailsBloc.close();
    super.dispose();
  }

  void _navigateToEditPage(Map<String, dynamic> typeData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTypePage(
          typeId: widget.typeId,
          typeData: typeData,
          onUpdate: () {
            _typeDetailsBloc.add(FetchTypeDetails(widget.typeId));
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete this type?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _typeDetailsBloc.add(DeleteType(widget.typeId));
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _typeDetailsBloc,
      child: BlocConsumer<TypeDetailsBloc, TypeDetailsState>(
        listener: (context, state) {
          if (state is TypeDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Type deleted successfully')),
            );
            Navigator.pop(context);
          } else if (state is TypeDeleteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is TypeDetailsInitial || state is TypeDetailsLoading) {
            return _buildLoadingScreen();
          } else if (state is TypeDetailsError) {
            return _buildErrorScreen(state.message);
          } else if (state is TypeDetailsLoaded) {
            _pageController.addListener(() {
              if (_pageController.page != null &&
                  _pageController.page!.round() != state.currentPage) {
                context
                    .read<TypeDetailsBloc>()
                    .add(ChangeImagePage(_pageController.page!.round()));
              }
            });
            return _buildDetailsScreen(context, state);
          }
          return _buildLoadingScreen();
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors().mainColor),
            SizedBox(height: 16),
            Text(
              'Loading details...',
              style: TextStyle(color: AppColors().mainColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors().mainColor,
        title: Text('Cake Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors().mainColor),
            SizedBox(height: 16),
            Text(
              'Cake type not found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors().mainColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsScreen(BuildContext context, TypeDetailsLoaded state) {
    final List<dynamic> images = state.typeData['images'] ?? [];
    final List<dynamic> weights = state.typeData['weights'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Image carousel with curved bottom edge
            _buildImageCarousel(context, images, state.currentPage),

            // Content section
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text(
                                      state.typeData['name'],
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _buildActionButton(
                                    icon: Icons.edit,
                                    color: AppColors().mainColor,
                                    backgroundColor:
                                        Colors.deepPurple.withOpacity(0.1),
                                    onTap: () =>
                                        _navigateToEditPage(state.typeData),
                                  ),
                                  SizedBox(width: 8),
                                  _buildActionButton(
                                    icon: Icons.delete,
                                    color: AppColors().mainColor,
                                    backgroundColor:
                                        Colors.deepPurple.withOpacity(0.1),
                                    onTap: _showDeleteConfirmationDialog,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: 24),

                          // Price section with beautiful card
                          _buildPriceCard(context, state),

                          SizedBox(height: 24),

                          // Description section
                          _buildSectionTitle('Description'),
                          SizedBox(height: 12),
                          Text(
                            state.typeData['description'],
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(height: 24),

                          // Weight selection
                          _buildSectionTitle('Select Weight'),
                          SizedBox(height: 16),
                          _buildWeightSelector(context, weights, state),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(
      BuildContext context, List<dynamic> images, int currentPage) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      width: double.infinity,
      child: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              context.read<TypeDetailsBloc>().add(ChangeImagePage(index));
            },
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors().mainColor,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              color: Colors.grey[400], size: 48),
                          SizedBox(height: 8),
                          Text('Image not available',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Back button with blur background
          Positioned(
            top: 16,
            left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    constraints: BoxConstraints.tightFor(width: 24, height: 24),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),

          // Page indicators
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  width: currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: currentPage == index
                        ? AppColors().mainColor
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, TypeDetailsLoaded state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors().mainColor, AppColors().subcolor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors().mainColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '${state.calculatedPrice > 0 ? state.calculatedPrice.toStringAsFixed(0) : state.baseRate.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (state.selectedWeight != null) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    state.selectedWeight!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (state.calculatedPrice == 0)
            Text(
              'Base rate per kg',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors().mainColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSelector(
      BuildContext context, List<dynamic> weights, TypeDetailsLoaded state) {
    return Container(
      width: double.infinity,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: weights.map((weight) {
          final bool isSelected = state.selectedWeight == weight;
          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 60,
            height: 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.read<TypeDetailsBloc>().add(
                        SelectWeight(weight.toString(), state.baseRate),
                      );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors().mainColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors().mainColor
                          : Colors.grey[300]!,
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors().mainColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      weight.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
