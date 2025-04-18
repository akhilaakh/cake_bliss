// import 'package:cake_bliss/category/fetchcategory.dart';
// import 'package:cake_bliss/customization/customization.dart';
// import 'package:cake_bliss/customization/customization_list.dart';
// import 'package:cake_bliss/types/type_view.dart';
// import 'package:flutter/material.dart';
// import 'package:cake_bliss/constants/app_colors.dart';
// import 'package:cake_bliss/services/auth_service.dart';
// import 'package:cake_bliss/Login/loginpage.dart';
// import 'package:cake_bliss/screen/cart.dart';
// import 'package:cake_bliss/screen/chat.dart';
// import 'package:cake_bliss/screen/favorite.dart';
// import 'package:cake_bliss/screen/profile.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final AuthService _auth = AuthService();
//   final FirestoreService _firestoreService = FirestoreService();
//   final TextEditingController _searchController = TextEditingController();
//   List<Category> _categories = [];
//   List<Category> _filteredCategories = [];
//   bool _isSearching = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadCategories();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _loadCategories() {
//     _firestoreService.fetchCategories().listen((categories) {
//       setState(() {
//         _categories = categories;
//         _filteredCategories = categories;
//       });
//     });
//   }

//   void _filterSearchResults(String query) {
//     if (query.isEmpty) {
//       setState(() {
//         _filteredCategories = _categories;
//         _isSearching = false;
//       });
//       return;
//     }

//     setState(() {
//       _isSearching = true;
//       _filteredCategories = _categories.where((category) {
//         final categoryNameMatch =
//             category.name.toLowerCase().contains(query.toLowerCase());
//         return categoryNameMatch;
//       }).toList();
//     });
//   }

//   void _showCustomizationDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Custom Cake Design',
//             style: TextStyle(
//               color: AppColors().mainColor,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           content: const Text(
//             'Would you like to create your own cake design?',
//             style: TextStyle(fontSize: 16),
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text(
//                 'No',
//                 style: TextStyle(color: AppColors().mainColor),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const CustomizationPage(),
//                   ),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors().mainColor,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text(
//                 'Yes',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _handleMenuItemClick(String value) async {
//     switch (value) {
//       case 'Customize':
//         _showCustomizationDialog();
//         break;
//       case 'Home':
//         break;
//       case 'Profile':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const Profile()),
//         );
//         break;
//       case 'Favorites':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const FavouritePage()),
//         );
//         break;
//       case 'Cart':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const CartPage()),
//         );
//         break;
//       case 'Chat':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const Chat()),
//         );
//         break;
//       case 'Sign Out':
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: const Text("Logout Confirmation"),
//               content: const Text("Are you sure you want to logout?"),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   child: const Text("Cancel"),
//                 ),
//                 TextButton(
//                   onPressed: () async {
//                     Navigator.of(context).pop();
//                     await _auth.signout();
//                     // ignore: use_build_context_synchronously
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const LoginPage(),
//                       ),
//                     );
//                   },
//                   child: const Text("Logout"),
//                 ),
//               ],
//             );
//           },
//         );
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           backgroundColor: AppColors().mainColor,
//           toolbarHeight: 150,
//           title: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const Text(
//                 'Cake Bliss',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   PopupMenuButton<String>(
//                     icon: const Icon(Icons.menu, color: Colors.white),
//                     onSelected: _handleMenuItemClick,
//                     itemBuilder: (BuildContext context) => [
//                       PopupMenuItem(
//                         value: 'Customize',
//                         child: Row(
//                           children: [
//                             Icon(Icons.cake, color: AppColors().mainColor),
//                             const SizedBox(width: 8),
//                             const Text('Custom Cake'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'Home',
//                         child: Row(
//                           children: [
//                             Icon(Icons.home, color: Colors.black),
//                             SizedBox(width: 8),
//                             Text('Home'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'Profile',
//                         child: Row(
//                           children: [
//                             Icon(Icons.person, color: Colors.black),
//                             SizedBox(width: 8),
//                             Text('Profile'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'Favorites',
//                         child: Row(
//                           children: [
//                             Icon(Icons.favorite, color: Colors.black),
//                             SizedBox(width: 8),
//                             Text('Favorites'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'Cart',
//                         child: Row(
//                           children: [
//                             Icon(Icons.shopping_cart, color: Colors.black),
//                             SizedBox(width: 8),
//                             Text('Cart'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'Chat',
//                         child: Row(
//                           children: [
//                             Icon(Icons.chat, color: Colors.black),
//                             SizedBox(width: 8),
//                             Text('Chat'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'Sign Out',
//                         child: Row(
//                           children: [
//                             Icon(Icons.exit_to_app, color: Colors.black),
//                             SizedBox(width: 8),
//                             Text('Sign Out'),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               SizedBox(
//                 height: 50,
//                 child: TextField(
//                   controller: _searchController,
//                   onChanged: _filterSearchResults,
//                   decoration: InputDecoration(
//                     hintText: 'Search categories...',
//                     hintStyle: const TextStyle(color: Color(0xFF6F2E00)),
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       borderSide: BorderSide.none,
//                     ),
//                     prefixIcon: Icon(
//                       Icons.search,
//                       color: AppColors().mainColor,
//                     ),
//                     suffixIcon: _searchController.text.isNotEmpty
//                         ? IconButton(
//                             icon: const Icon(Icons.clear),
//                             onPressed: () {
//                               _searchController.clear();
//                               _filterSearchResults('');
//                             },
//                           )
//                         : null,
//                   ),
//                   style: const TextStyle(color: Color(0xFF6F2E00)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         body: SingleChildScrollView(
//           child: Column(
//             children: [
//               // Customization Banner
//               Container(
//                 width: double.infinity,
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                 margin: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: AppColors().mainColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: AppColors().mainColor),
//                 ),
//                 child: InkWell(
//                   onTap: _showCustomizationDialog,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Create Your Custom Cake',
//                         style: TextStyle(
//                           color: AppColors().mainColor,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Icon(
//                         Icons.arrow_forward_ios,
//                         color: AppColors().mainColor,
//                         size: 20,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => CustomizationList()),
//                   );
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: AppColors().mainColor,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Text(
//                     "Customization",
//                     style: TextStyle(color: Colors.white, fontSize: 18),
//                   ),
//                 ),
//               ),
//               SizedBox(
//                 height: MediaQuery.of(context).size.height *
//                     0.4, // Adjust this value as needed
//                 child: _isSearching && _filteredCategories.isEmpty
//                     ? const Center(
//                         child: Text('No matching categories found'),
//                       )
//                     : StreamBuilder<List<Category>>(
//                         stream: _firestoreService.fetchCategories(),
//                         builder: (context, snapshot) {
//                           if (snapshot.connectionState ==
//                               ConnectionState.waiting) {
//                             return const Center(
//                                 child: CircularProgressIndicator());
//                           } else if (snapshot.hasError) {
//                             return const Center(
//                                 child: Text('Error fetching categories'));
//                           } else if (!snapshot.hasData ||
//                               snapshot.data!.isEmpty) {
//                             return const Center(
//                                 child: Text('No categories available'));
//                           } else {
//                             return Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: ListView.builder(
//                                 scrollDirection: Axis.horizontal,
//                                 itemCount: _filteredCategories.length,
//                                 itemBuilder: (context, index) {
//                                   final category = _filteredCategories[index];
//                                   return CategoryCard(category: category);
//                                 },
//                               ),
//                             );
//                           }
//                         },
//                       ),
//               ),
//             ],
//           ),
//         ));
//   }
// }

// class CategoryCard extends StatelessWidget {
//   final Category category;

//   const CategoryCard({Key? key, required this.category}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => Viewpage(categoryName: category.name),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             ClipOval(
//               child: category.imageUrl.isNotEmpty
//                   ? Image.network(
//                       category.imageUrl,
//                       height: 100,
//                       width: 100,
//                       fit: BoxFit.cover,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return Container(
//                           height: 100,
//                           width: 100,
//                           color: Colors.grey[300],
//                           child: Center(
//                             child: CircularProgressIndicator(
//                               value: loadingProgress.expectedTotalBytes != null
//                                   ? loadingProgress.cumulativeBytesLoaded /
//                                       loadingProgress.expectedTotalBytes!
//                                   : null,
//                               color: AppColors().mainColor,
//                             ),
//                           ),
//                         );
//                       },
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           height: 100,
//                           width: 100,
//                           color: Colors.grey[300],
//                           child: Icon(
//                             Icons.cake,
//                             color: AppColors().mainColor,
//                             size: 40,
//                           ),
//                         );
//                       },
//                     )
//                   : Container(
//                       height: 100,
//                       width: 100,
//                       color: Colors.grey[300],
//                       child: Icon(
//                         Icons.cake,
//                         color: AppColors().mainColor,
//                         size: 40,
//                       ),
//                     ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               category.name,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// home_page.dart
// home_page.dart
import 'package:cake_bliss/about_us.dart';
import 'package:cake_bliss/bloc/home/block.dart';
import 'package:cake_bliss/bloc/home/event.dart';
import 'package:cake_bliss/bloc/home/state.dart';
import 'package:cake_bliss/category/fetchcategory.dart';
import 'package:cake_bliss/checkout/checkout_cart.dart';
import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cake_bliss/customization/customization.dart';
import 'package:cake_bliss/customization/customization_list.dart';
import 'package:cake_bliss/Login/loginpage.dart';
import 'package:cake_bliss/offer.dart';
import 'package:cake_bliss/privacy_policy.dart';
import 'package:cake_bliss/screen/cart.dart';
import 'package:cake_bliss/screen/favorite.dart';
import 'package:cake_bliss/screen/profile.dart';
import 'package:cake_bliss/services/auth_service.dart';
import 'package:cake_bliss/terms_and_conditions.dart';
import 'package:cake_bliss/types/type_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use BlocProvider.value if returning to an existing page
    // or create a new one if it doesn't exist
    return BlocProvider(
      create: (context) => HomeBloc(
        authService: AuthService(),
        firestoreService: FirestoreService(),
      )..add(LoadCategoriesEvent()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final CarouselController _carouselController = CarouselController();
  int _currentImageIndex = 0;

  // Corrected slider images with proper asset paths
  final List<String> sliderImages = [
    'asset/ChatGPT Image Apr 16, 2025, 10_11_25 AM.png',
    'asset/ChatGPT Image Apr 16, 2025, 10_38_04 AM.png'
  ];

  @override
  bool get wantKeepAlive => true; // Keep this page alive when navigating

  @override
  void initState() {
    super.initState();
    // Ensure categories are loaded every time we visit this page
    Future.microtask(() => context.read<HomeBloc>().add(LoadCategoriesEvent()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCustomizationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Custom Cake Design',
            style: TextStyle(
              color: AppColors().mainColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Would you like to create your own cake design?',
            style: TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'No',
                style: TextStyle(color: AppColors().mainColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomizationPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors().mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleNavigation(String page, BuildContext context) {
    switch (page) {
      case 'Customize':
        _showCustomizationDialog();
        break;
      case 'Home':
        break;
      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Profile()),
        ).then((_) {
          // Refresh categories when returning from Profile
          context.read<HomeBloc>().add(LoadCategoriesEvent());
        });
        break;
      case 'Favorites':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FavouritePage()),
        ).then((_) {
          // Refresh categories when returning from Favorites
          context.read<HomeBloc>().add(LoadCategoriesEvent());
        });
        break;
      case 'Cart':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CartPage()),
        ).then((_) {
          // Refresh categories when returning from Cart
          context.read<HomeBloc>().add(LoadCategoriesEvent());
        });
        break;
      case 'Orders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrdersHistoryPage()),
        ).then((_) {
          // Refresh categories when returning from Orders
          context.read<HomeBloc>().add(LoadCategoriesEvent());
        });
        break;
      case 'TermsAndConditions':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TermsAndCondition()),
        ).then((_) {
          // Refresh categories when returning from Terms
          context.read<HomeBloc>().add(LoadCategoriesEvent());
        });
        break;
      case 'Privacypolicy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Privacypolicy()),
        ).then((_) {
          // Refresh categories when returning from Privacy Policy
          context.read<HomeBloc>().add(LoadCategoriesEvent());
        });
        break;
      case 'AboutUs':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutUs()),
        ).then((_) {
          // Refresh categories when returning from About Us
          context.read<HomeBloc>().add(LoadCategoriesEvent());
        });
        break;
      case 'Chat':
        // Add navigation for Chat feature
        // Navigator.push(...).then((_) {
        //   context.read<HomeBloc>().add(LoadCategoriesEvent());
        // });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is ShowCustomizationDialogState) {
          _showCustomizationDialog();
        } else if (state is NavigateToPageState) {
          _handleNavigation(state.page, context);
        } else if (state is ConfirmSignOutState) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Logout Confirmation"),
                content: const Text("Are you sure you want to logout?"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.read<HomeBloc>().add(SignOutEvent());
                    },
                    child: const Text("Logout"),
                  ),
                ],
              );
            },
          );
        } else if (state is SignOutSuccessState) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: AppColors().mainColor,
            toolbarHeight: 150,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Cake Bliss',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onSelected: (value) {
                        context
                            .read<HomeBloc>()
                            .add(NavigateToPageEvent(value));
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'Customize',
                          child: Row(
                            children: [
                              Icon(Icons.cake, color: AppColors().mainColor),
                              const SizedBox(width: 8),
                              const Text('Custom Cake'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'Home',
                          child: Row(
                            children: [
                              Icon(Icons.home, color: Colors.black),
                              SizedBox(width: 8),
                              Text('Home'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'Profile',
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.black),
                              SizedBox(width: 8),
                              Text('Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'Favorites',
                          child: Row(
                            children: [
                              Icon(Icons.favorite, color: Colors.black),
                              SizedBox(width: 8),
                              Text('Favorites'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'Orders',
                          child: Row(
                            children: [
                              Icon(Icons.history, color: Colors.black),
                              SizedBox(width: 8),
                              Text('order'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'Cart',
                          child: Row(
                            children: [
                              Icon(Icons.shopping_cart, color: Colors.black),
                              SizedBox(width: 8),
                              Text('Cart'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'Chat',
                          child: Row(
                            children: [
                              Icon(Icons.chat, color: Colors.black),
                              SizedBox(width: 8),
                              Text('Chat'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'Privacypolicy',
                          child: Row(
                            children: [
                              Icon(Icons.privacy_tip_outlined,
                                  color: Colors.black),
                              SizedBox(width: 8),
                              Text('privacy policy'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'TermsAndConditions',
                          child: Row(
                            children: [
                              Icon(Icons.rule_folder, color: Colors.black),
                              SizedBox(width: 8),
                              Text('TermsAndConditions'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'AboutUs',
                          child: Row(
                            children: [
                              Icon(Icons.abc_outlined, color: Colors.black),
                              SizedBox(width: 8),
                              Text('AboutUs'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 50,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (query) {
                      context
                          .read<HomeBloc>()
                          .add(SearchCategoriesEvent(query));
                    },
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      hintStyle: const TextStyle(color: Color(0xFF6F2E00)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors().mainColor,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<HomeBloc>()
                                    .add(ClearSearchEvent());
                              },
                            )
                          : null,
                    ),
                    style: const TextStyle(color: Color(0xFF6F2E00)),
                  ),
                ),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Add refresh functionality
              context.read<HomeBloc>().add(LoadCategoriesEvent());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Image Slider Section (Carousel)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: CarouselSlider(
                      items: sliderImages.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final String imageUrl = entry.value;

                        return GestureDetector(
                          onTap: () {
                            // Navigate to the list page when an image is clicked
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserOfferListPage(),
                              ),
                            ).then((_) {
                              // Refresh categories when returning from UserOfferListPage
                              context
                                  .read<HomeBloc>()
                                  .add(LoadCategoriesEvent());
                            });
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  // Image - Using Image.asset instead of Image.network
                                  Positioned.fill(
                                    child: Image.asset(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: Center(
                                            child: Icon(
                                              Icons.cake,
                                              color: AppColors().mainColor,
                                              size: 50,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Optional: Add an overlay or indicator to show it's clickable
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text(
                                            'View All',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      carouselController: _carouselController,
                      options: CarouselOptions(
                        autoPlay: true,
                        enlargeCenterPage: true,
                        aspectRatio: 16 / 9,
                        viewportFraction: 0.8,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                      ),
                    ),
                  ),

                  // Carousel Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: sliderImages.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () =>
                            _carouselController.animateToPage(entry.key),
                        child: Container(
                          width: 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : AppColors().mainColor)
                                    .withOpacity(
                              _currentImageIndex == entry.key ? 0.9 : 0.4,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Categories Section in Single Line
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors().mainColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        BlocBuilder<HomeBloc, HomeState>(
                          builder: (context, state) {
                            if (state is HomeLoadingState) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (state is HomeErrorState) {
                              return Center(
                                child: Column(
                                  children: [
                                    Text(state.message),
                                    ElevatedButton(
                                      onPressed: () {
                                        context
                                            .read<HomeBloc>()
                                            .add(LoadCategoriesEvent());
                                      },
                                      child: const Text("Retry"),
                                    ),
                                  ],
                                ),
                              );
                            } else if (state is HomeCategoriesLoadedState) {
                              if (state.isSearching &&
                                  state.filteredCategories.isEmpty) {
                                return const Center(
                                    child:
                                        Text('No matching categories found'));
                              }

                              return Container(
                                height:
                                    150, // Fixed height for the categories row
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: state.filteredCategories.length,
                                  itemBuilder: (context, index) {
                                    final category =
                                        state.filteredCategories[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: CategoryCard(category: category),
                                    );
                                  },
                                ),
                              );
                            }
                            // Add a retry button if no state matches (likely initial state)
                            return Center(
                              child: Column(
                                children: [
                                  const Text('No categories available'),
                                  ElevatedButton(
                                    onPressed: () {
                                      context
                                          .read<HomeBloc>()
                                          .add(LoadCategoriesEvent());
                                    },
                                    child: const Text("Load Categories"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Customization Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors().mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors().mainColor),
                    ),
                    child: InkWell(
                      onTap: () {
                        context.read<HomeBloc>().add(CustomizeCakeEvent());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Create Your Custom Cake',
                            style: TextStyle(
                              color: AppColors().mainColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors().mainColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Customization Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CustomizationList()),
                      ).then((_) {
                        // Refresh categories when returning from CustomizationList
                        context.read<HomeBloc>().add(LoadCategoriesEvent());
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors().mainColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Customization",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TypeViewPage(categoryName: category.name),
          ),
        ).then((_) {
          // Refresh categories when returning from TypeViewPage
          context.read<HomeBloc>().add(LoadCategoriesEvent());
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: category.imageUrl.isNotEmpty
                ? Image.network(
                    category.imageUrl,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors().mainColor,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.cake,
                          color: AppColors().mainColor,
                          size: 40,
                        ),
                      );
                    },
                  )
                : Container(
                    height: 100,
                    width: 100,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.cake,
                      color: AppColors().mainColor,
                      size: 40,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: Text(
              category.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
