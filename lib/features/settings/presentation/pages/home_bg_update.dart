// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';

// class HomeBgUpdate extends StatefulWidget {
//   const HomeBgUpdate({super.key});

//   @override
//   State<HomeBgUpdate> createState() => _HomeBgUpdateState();
// }

// class _HomeBgUpdateState extends State<HomeBgUpdate> {
//   File? _selectedImage;
//   bool _isLoading = false;
//   String? _errorMessage;

//   // Target dimensions
//   static const double targetWidth = 1536;
//   static const double targetHeight = 1024;

//   Future<void> _pickAndCropImage() async {
//     setState(() {
//       _errorMessage = null;
//       _isLoading = true;
//     });

//     try {
//       // Pick image from gallery
//       final ImagePicker picker = ImagePicker();
//       final XFile? image = await picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: targetWidth * 2,
//         maxHeight: targetHeight * 2,
//         imageQuality: 90,
//       );

//       if (image == null) {
//         setState(() => _isLoading = false);
//         return;
//       }

//       // Crop image to exact dimensions - FIXED ASPECT RATIO
//       final CroppedFile? croppedImage = await ImageCropper().cropImage(
//         sourcePath: image.path,
//         aspectRatio: const CropAspectRatio(
//           ratioX: 1536, // Use actual width as integer
//           ratioY: 1024, // Use actual height as integer
//         ),
//         uiSettings: [
//           AndroidUiSettings(
//             toolbarTitle: 'Crop Image',
//             toolbarColor: Colors.deepPurple,
//             toolbarWidgetColor: Colors.white,
            
//             lockAspectRatio: true,
//             backgroundColor: Colors.black,
//             hideBottomControls: false,
//             showCropGrid: true,
//           ),
//           IOSUiSettings(
//             title: 'Crop Image',
//             aspectRatioLockEnabled: true,
//             resetAspectRatioEnabled: false,
//             aspectRatioPickerButtonHidden: true,
//           ),
//         ],
//         compressQuality: 90,
//         compressFormat: ImageCompressFormat.jpg,
//       );

//       if (croppedImage != null) {
//         final File croppedFile = File(croppedImage.path);
//         setState(() {
//           _selectedImage = croppedFile;
//           _isLoading = false;
//         });
//         _showSuccessSnackBar('Image cropped successfully!');
//       } else {
//         setState(() => _isLoading = false);
//       }
//     } catch (e) {
//       debugPrint('Error: $e');
//       setState(() {
//         _errorMessage = 'Error processing image: ${e.toString()}';
//         _isLoading = false;
//       });
//     }
//   }

//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   void _removeImage() {
//     setState(() {
//       _selectedImage = null;
//       _errorMessage = null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final isSmallScreen = screenSize.width < 600;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Update Image'),
//         backgroundColor: Colors.deepPurple,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
//             child: ConstrainedBox(
//               constraints: BoxConstraints(
//                 maxWidth: isSmallScreen ? double.infinity : 800,
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Preview Section
//                   Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Container(
//                       width: double.infinity,
//                       constraints: BoxConstraints(
//                         minHeight: isSmallScreen ? 200 : 300,
//                       ),
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Header
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   color: Colors.deepPurple.shade50,
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Icon(
//                                   Icons.image,
//                                   color: Colors.deepPurple,
//                                   size: isSmallScreen ? 20 : 24,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Image Preview',
//                                       style: TextStyle(
//                                         fontSize: isSmallScreen ? 18 : 20,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     Text(
//                                       'Required: 1536 x 1024 px',
//                                       style: TextStyle(
//                                         fontSize: isSmallScreen ? 12 : 14,
//                                         color: Colors.grey.shade600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               if (_selectedImage != null)
//                                 IconButton(
//                                   onPressed: _removeImage,
//                                   icon: const Icon(Icons.close, color: Colors.red),
//                                   tooltip: 'Remove image',
//                                 ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),

//                           // Image Preview Area
//                           Container(
//                             width: double.infinity,
//                             height: isSmallScreen ? 200 : 300,
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade100,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: Colors.grey.shade300,
//                                 width: 2,
//                               ),
//                             ),
//                             child: _buildPreviewContent(),
//                           ),

//                           if (_errorMessage != null) ...[
//                             const SizedBox(height: 16),
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.red.shade50,
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: Colors.red.shade200),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.error_outline, color: Colors.red.shade700),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: Text(
//                                       _errorMessage!,
//                                       style: TextStyle(color: Colors.red.shade700),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],

//                           // Dimensions info
//                           if (_selectedImage != null) ...[
//                             const SizedBox(height: 16),
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.deepPurple.shade50,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.check_circle,
//                                     color: Colors.deepPurple,
//                                     size: 16,
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     'Image ready for update',
//                                     style: TextStyle(
//                                       color: Colors.deepPurple.shade700,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // Action Buttons
//                   if (_selectedImage == null) ...[
//                     // Select Image Button
//                     SizedBox(
//                       width: double.infinity,
//                       height: isSmallScreen ? 50 : 56,
//                       child: ElevatedButton.icon(
//                         onPressed: _isLoading ? null : _pickAndCropImage,
//                         icon: _isLoading
//                             ? const SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: Colors.white,
//                                 ),
//                               )
//                             : const Icon(Icons.photo_library),
//                         label: Text(
//                           _isLoading ? 'Processing...' : 'Select from Gallery',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 14 : 16,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.deepPurple,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 4,
//                         ),
//                       ),
//                     ),
//                   ] else ...[
//                     // Update Button
//                     SizedBox(
//                       width: double.infinity,
//                       height: isSmallScreen ? 50 : 56,
//                       child: ElevatedButton.icon(
//                         onPressed: () {
//                           _showSuccessSnackBar('Image ready for upload!');
//                         },
//                         icon: const Icon(Icons.cloud_upload),
//                         label: Text(
//                           'Update Image',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 14 : 16,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 4,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPreviewContent() {
//     if (_selectedImage != null) {
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(10),
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             Image.file(
//               _selectedImage!,
//               fit: BoxFit.contain,
//               errorBuilder: (context, error, stackTrace) {
//                 return Container(
//                   color: Colors.grey.shade200,
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.broken_image,
//                           size: 48,
//                           color: Colors.grey.shade400,
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Failed to load image',
//                           style: TextStyle(color: Colors.grey.shade600),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//             // Dimension overlay
//             Positioned(
//               bottom: 8,
//               right: 8,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withValues(alpha:0.7),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: const Text(
//                   '1536 x 1024',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.image_outlined,
//             size: 64,
//             color: Colors.grey.shade400,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No image selected',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Tap the button below to select an image',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }