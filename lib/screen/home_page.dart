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
import 'package:cake_bliss/bloc/home/block.dart';
import 'package:cake_bliss/bloc/home/event.dart';
import 'package:cake_bliss/bloc/home/state.dart';
import 'package:cake_bliss/category/fetchcategory.dart';
import 'package:cake_bliss/checkout/checkout_cart.dart';
import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cake_bliss/customization/customization.dart';
import 'package:cake_bliss/customization/customization_list.dart';
import 'package:cake_bliss/Login/loginpage.dart';
import 'package:cake_bliss/privacy_policy.dart';
import 'package:cake_bliss/screen/cart.dart';
import 'package:cake_bliss/screen/favorite.dart';
import 'package:cake_bliss/screen/profile.dart';
import 'package:cake_bliss/services/auth_service.dart';
import 'package:cake_bliss/terms_and_conditions.dart';
import 'package:cake_bliss/types/type_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();

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
        );
        break;
      case 'Favorites':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FavouritePage()),
        );
        break;
      case 'Cart':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CartPage()),
        );
        break;
      case 'Orders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrdersHistoryPage()),
        );
        break;
      case 'TermsAndConditions':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TermsAndCondition()),
        );
        break;
      case 'Privacypolicy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Privacypolicy()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        // const PopupMenuItem(
                        //   value: 'Sign Out',
                        //   child: Row(
                        //     children: [
                        //       Icon(Icons.exit_to_app, color: Colors.black),
                        //       SizedBox(width: 8),
                        //       Text('Sign Out'),
                        //     ],
                        //   ),
                        // ),
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
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Customization Banner
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CustomizationList()),
                    );
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
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      if (state is HomeLoadingState) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is HomeErrorState) {
                        return Center(child: Text(state.message));
                      } else if (state is HomeCategoriesLoadedState) {
                        if (state.isSearching &&
                            state.filteredCategories.isEmpty) {
                          return const Center(
                              child: Text('No matching categories found'));
                        }

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.filteredCategories.length,
                            itemBuilder: (context, index) {
                              final category = state.filteredCategories[index];
                              return CategoryCard(category: category);
                            },
                          ),
                        );
                      }
                      return const Center(
                          child: Text('No categories available'));
                    },
                  ),
                ),
              ],
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
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
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
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
