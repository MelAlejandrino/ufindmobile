import 'dart:io';  // For file handling
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';  // For DateFormat
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';  // For image selection
import 'package:supabase_flutter/supabase_flutter.dart';  // For Supabase upload
import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'dart:typed_data'; // For Uint8List
import 'dart:math';
import 'package:flutter/services.dart';

class TicketDetailsPage extends StatefulWidget {
  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>(); // Key to control scaffold messenger

  // Form Fields
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();

  String _lastSeenLocation = "Tap to pin location";
  LatLng? _selectedLocation;
  String _itemType = '';  // 'Lost' or 'Found'
  String _status = '';  // 'Lost' or 'Found'
  bool _isLoading = false;
  String _claimStatus = '';

  // Image Upload Fields
  File? _selectedImage;  // Selected image file
  final ImagePicker _picker = ImagePicker();  // Image picker instance
  String? _imageUrl;  // URL of the uploaded image

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedContactInfo();
  }

  Future<void> _loadSavedContactInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get saved Full Name and Email using the correct keys
    String? savedFirstName = prefs.getString('user_first_name');
    String? savedLastName = prefs.getString('user_last_name');
    String? savedEmail = prefs.getString('user_email');
    String? savedNumber = prefs.getString('contact_number');

    // Set the initial values if they exist
    if (savedFirstName != null && savedLastName != null) {
      _contactNameController.text = '$savedFirstName $savedLastName'; // Combine first and last name
    }
    if (savedEmail != null) {
      _emailController.text = savedEmail;
    }
    if (savedNumber != null) {
      _contactNumberController.text = savedNumber;
    }
  }


  // Show Item Type Selection Dialog
// Show Item Type Selection Dialog
  void _showItemTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Item Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Lost'),
              onTap: () {
                setState(() {
                  _itemType = 'lost';
                });
                Navigator.pop(context); // Close the item type dialog
              },
            ),
            ListTile(
              title: const Text('Found'),
              onTap: () async {
                setState(() {
                  _itemType = 'found';
                });
                Navigator.pop(context); // Close the item type dialog
                await _showOwnershipDialog(); // Show the ownership dialog
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<File?> _compressImage(File image) async {
    // Read the image as bytes (Uint8List)
    final Uint8List imageBytes = await image.readAsBytes();

    // Compress the image using flutter_image_compress
    final List<int> result = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 400, // Resize width (adjust as needed)
      quality: 50,    // Set the quality (lower for better compression)
    );

    // Convert List<int> result to Uint8List
    final Uint8List compressedBytes = Uint8List.fromList(result);

    // Create a new file with the compressed bytes
    final compressedImage = File(image.path)..writeAsBytesSync(compressedBytes);

    return compressedImage;
  }

  // Upload Image to Supabase with compression
  Future<String?> _uploadImageToSupabase() async {
    // If no image is selected, use the default image from assets
    _selectedImage ??= await _loadAssetImage('assets/default_image.png');

    try {
      // Compress the image before uploading
      File? compressedImage = await _compressImage(_selectedImage!);

      if (compressedImage == null) {
        throw Exception('Error compressing image');
      }

      // Create a unique file name with a timestamp to avoid overwriting
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload the compressed image to Supabase storage
      final response = await Supabase.instance.client.storage
          .from('images') // 'images' is the name of your bucket
          .upload(fileName, compressedImage);

      // Check if the upload was successful
      if (response.error != null) {
        // throw response.error!;
      }

      // Retrieve the public URL for the uploaded file
      final publicUrl = 'https://tqvgagdffmjtxswldtgm.supabase.co/storage/v1/object/public/images/$fileName';

      // Return the URL as a string
      return publicUrl;

    } catch (e) {
      // print('Error uploading image: $e');
      // Handle any errors during upload
      return null;
    }
  }

// Load image from assets and return it as a File object
  Future<File?> _loadAssetImage(String path) async {
    try {
      // Load the image as a byte array from assets
      final ByteData data = await rootBundle.load(path);
      final List<int> bytes = data.buffer.asUint8List();

      // Create a temporary file to store the asset image
      final tempFile = File('${Directory.systemTemp.path}/temp_image.png');
      await tempFile.writeAsBytes(bytes);

      return tempFile;
    } catch (e) {
      // print('Error loading asset image: $e');
      return null;
    }
  }

  // bool _validateContactNumber(String contactNumber) {
  //   // Ensure the contact number is not empty and consists of only digits
  //   return contactNumber.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(contactNumber);
  // }
  //
  //
  // // Email Validation
  // bool _validateEmail(String email) {
  //   return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email); // Basic email validation
  // }


  Future<void> _showOwnershipDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('user_school_id');

    if (savedId == '1234567890') {
      // Automatically select 'TurnOver' for savedId == '1234567890' and set contact details
      setState(() {
        _status = 'TurnOver'; // Set status to 'Turnover'
        _contactNameController.text = 'Campus Security - Gate Entrance';
        _contactNumberController.text = '000000000';
        _emailController.text = 'noemail@gmail.com';
      });
    } else {
      // Show the dialog for other users
      await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Keep/Turnover'),
          content: const Text(
              'Are you going to keep the item and give it yourself, or turn it over to Campus Security - Gate Entrance'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _status = 'Keep'; // Set status to 'Keep'
                  // Clear contact details for 'Keep' if needed
                });
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _status = 'TurnOver'; // Set status to 'Turnover'
                  // Automatically set the contact details for 'TurnOver'
                  _contactNameController.text = 'Campus Security - Gate Entrance';
                  _contactNumberController.text = '000000000';
                  _emailController.text = 'noemail@gmail.com';
                });
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Turn Over'),
            ),
          ],
        ),
      );
    }
  }



  Future<void> _saveToFirebase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? schoolId = prefs.getString('user_school_id');

    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student ID not found. Please log in again.')),
      );
      return;
    }

    // Validate form fields and show specific warnings
    String missingFields = '';

    if (_itemType.isEmpty) {
      missingFields += 'Item Type (Lost/Found), ';
    }
    if (_itemNameController.text.isEmpty) {
      missingFields += 'Item Name, ';
    }
    if (_descriptionController.text.isEmpty) {
      missingFields += 'Description, ';
    }
    if (_dateTimeController.text.isEmpty) {
      missingFields += 'Date & Time, ';
    }
    if (_contactNameController.text.isEmpty) {
      missingFields += 'Full Name, ';
    }
    if (_contactNumberController.text.isEmpty) {
      missingFields += 'Contact Number, ';
    }
    if (_emailController.text.isEmpty) {
      missingFields += 'Email, ';
    }
    if (_locationNameController.text.isEmpty) {
      missingFields += 'Last Known Location, ';
    }
    if (_lastSeenLocation == "Tap to pin location" || _selectedLocation == null) {
      missingFields += 'Pinned Location, ';
    }

    // Remove trailing comma and space
    if (missingFields.isNotEmpty) {
      missingFields = missingFields.substring(0, missingFields.length - 2);
      _showTopSnackBar('Please fill in the following fields: $missingFields');
      return;
    }

    String uniqueId = _generateRandomId();
    String documentId = '${schoolId}_$uniqueId'; // Use schoolId + unique ID for "Keep"

    if (_status == 'TurnOver') {
      _claimStatus = 'turnover(guard)';
    } else {
      _claimStatus = 'keep';
    }

    // Save the ticket details to Firestore
    await FirebaseFirestore.instance.collection('items').doc(documentId).set({
      'status': _itemType,
      'name': _itemNameController.text,
      'description': _descriptionController.text,
      'dateTime': _dateTimeController.text,
      'fullName': _contactNameController.text,
      'contactNumber': _contactNumberController.text,
      'email': _emailController.text,
      'lastSeenLocation': _locationNameController.text,
      'location': _lastSeenLocation,
      'studentId': schoolId,
      'ticket': 'pending',
      'imageUrl': _imageUrl,
      'claimStatus': _claimStatus,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item Submitted Successfully!')),
    );

    if (context.mounted) {
      Navigator.pop(context);
    }
  }



// Generate 8-character random alphanumeric ID
  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }


  Future<void> _pickDateTime() async {
    DateTime initialDate = DateTime.now();
    DateTime pickedDate = (await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    )) ??
        initialDate;

    TimeOfDay pickedTime = (await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    )) ??
        TimeOfDay.fromDateTime(initialDate);

    setState(() {
      _dateTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(
        DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute),
      );
    });
  }


  // Pick an Image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Pick Location
  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(
          initialPosition: LatLng(8.485738, 124.657011),
        ),
      ),
    );

    if (result != null && result is LatLng) {
      setState(() {
        _selectedLocation = result;
        _lastSeenLocation = '${result.latitude}, ${result.longitude}';
      });
    }
  }

  // UI Elements
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey, // Set the scaffoldMessengerKey here
      appBar: AppBar(
        title: const Text("Item Details"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Item Info"),
            Tab(text: "Contact Info"),
          ],
        ),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.blue[50], // Light blue background for the card
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon for the reminder
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange[700],
                    size: 30,
                  ),
                  const SizedBox(width: 10), // Add space between icon and text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reminder:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 8), // Add space between "Reminder" and the text
                        const Text(
                          "Avoid providing excessive description about the item to prevent false claims. Also, verify the claimer's identity by checking their School ID.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton(
              onPressed: _showItemTypeDialog,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.lightBlueAccent), // Bright color to make it stand out
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners for better look
                  ),
                ),
                elevation: WidgetStateProperty.all(8), // Add elevation for a shadow effect
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 13.0, horizontal: 24.0), // Larger padding for a bigger button
                ),
              ),
              child: Text(
                _itemType.isEmpty
                    ? 'Is Item Lost or Found?'
                    : 'Selected: ${_itemType[0].toUpperCase()}${_itemType.substring(1)}', // Dynamically show "Lost" or "Found"
                style: const TextStyle(
                  fontSize: 15, // Larger text for better readability
                  fontWeight: FontWeight.bold, // Bold text for more emphasis
                  color: Colors.white, // White text color for contrast
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketInfoTab(),
                _buildContactInfoTab(),
              ],
            ),
          ),

        ],
      ),
    );
  }

  void _showTopSnackBar(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50, // Adjust position from the top
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8.0),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove the snackBar after 3 seconds
    Future.delayed(const Duration(seconds: 5), () {
      overlayEntry.remove();
    });
  }

  Widget _buildTicketInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ListView(
        children: [
          _buildTextField("Item Name", _itemNameController, icon: Icons.shopping_bag),  // Add icon
          _buildTextField("Description", _descriptionController, icon: Icons.description), // Add icon
          GestureDetector(
            onTap: _pickDateTime,
            child: AbsorbPointer(
              child: _buildTextField("Date & Time", _dateTimeController, icon: Icons.calendar_today),  // Add icon
            ),
          ),
          _buildTextField("Last Known Location", _locationNameController, placeholder: "Eg. Near Cafet, Near Library", icon: Icons.location_on), // Add icon
          GestureDetector(
            onTap: _pickLocation,
            child: AbsorbPointer(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Background color for the button-like appearance
                  border: Border.all(color: Colors.lightBlueAccent, width: 2), // Border color and width
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5), // Optional: Add shadow for depth
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // Shadow position
                    ),
                  ],
                ),
                child: ListTile(
                  title: const Text(
                    "Pin on Map",
                    style: TextStyle(fontWeight: FontWeight.bold), // Optional: Emphasize text
                  ),
                  subtitle: Text(_lastSeenLocation),
                  trailing: const Icon(Icons.map, color: Colors.lightBlueAccent), // Optional: Match border color
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          ElevatedButton.icon(
            onPressed: _pickImage,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.white), // Optional: White background
              foregroundColor: WidgetStateProperty.all(Colors.lightBlueAccent), // Red text and icon color
              side: WidgetStateProperty.all(
                const BorderSide(color: Colors.lightBlueAccent, width: 2), // Border color and width
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Padding for better click area
              ),
            ),
            icon: const Icon(
              Icons.image, // Icon representing picking an image
              size: 20,
              color: Colors.black,
            ),
            label: Text(
              _selectedImage == null ? 'Pick Image' : 'Change Image',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black), // Text styling
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: _isLoading
                ? const CircularProgressIndicator() // Show loading indicator if saving
                : ElevatedButton(
              onPressed: () async {
                // Prevent multiple clicks by setting the loading state
                setState(() {
                  _isLoading = true;
                });

                try {
                  // Upload image to Supabase first and get the image URL
                  final imageUrl = await _uploadImageToSupabase();

                  // Check if the image upload was successful
                  if (imageUrl != null) {
                    setState(() {
                      _imageUrl = imageUrl; // Set the image URL after successful upload
                    });

                    // Proceed to save the ticket details to Firebase
                    await _saveToFirebase();

                  } else {
                    // If image upload fails, show an error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image upload failed. Please try again.')),
                    );
                  }
                } catch (e) {
                  // If there is an error, show the error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                } finally {
                  // Reset the loading state, whether success or failure
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent, // Set background color
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Add padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Submit Item",
                    style: TextStyle(color: Colors.black), // Set text color
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildTextField("Full Name", _contactNameController, placeholder: "Enter your full name", icon: Icons.person),
          TextField(
            controller: _contactNumberController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Restricts input to digits only
            ],
            decoration: const InputDecoration(
              labelText: "Contact Number",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),  // Add the phone icon to the left
            ),
          ),
          _buildTextField("Email", _emailController, placeholder: "Enter your email", icon: Icons.email),
          const SizedBox(height: 20),
          Center(
            child: _isLoading
                ? const CircularProgressIndicator() // Show loading indicator if saving
                : ElevatedButton(
              onPressed: () async {
                // Prevent multiple clicks by setting the loading state
                setState(() {
                  _isLoading = true;
                });

                try {
                  // Upload image to Supabase first and get the image URL
                  final imageUrl = await _uploadImageToSupabase();

                  // Check if the image upload was successful
                  if (imageUrl != null) {
                    setState(() {
                      _imageUrl = imageUrl; // Set the image URL after successful upload
                    });

                    // Proceed to save the ticket details to Firebase
                    await _saveToFirebase();

                  } else {
                    // If image upload fails, show an error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image upload failed. Please try again.')),
                    );
                  }
                } catch (e) {
                  // If there is an error, show the error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                } finally {
                  // Reset the loading state, whether success or failure
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent, // Set background color
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Add padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 8), // Add spacing between icon and text
                  Text(
                    "Submit Item",
                    style: TextStyle(color: Colors.black), // Set text color
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? placeholder, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,  // Set placeholder text
          border: const OutlineInputBorder(),
          prefixIcon: icon != null ? Icon(icon) : null,  // Add the icon if provided
        ),
      ),
    );
  }
}

extension on String {
  get error => null;
}

class MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  const MapPickerScreen({required this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng selectedLocation;
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialPosition;
    mapController = MapController();
    // Ensure the map is rendered before interacting with the MapController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // You can now safely use mapController
      mapController.move(widget.initialPosition, 18.0); // Move map to initial position
    });

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),
      body: FlutterMap(
        mapController: mapController, // Pass the mapController
        options: MapOptions(
          initialCenter: widget.initialPosition,
          initialZoom: 18.0,
          minZoom: 18,
          onPositionChanged: (MapCamera camera, bool isAnimated) {
            // Define your bounds
            final LatLngBounds bounds = LatLngBounds(
              LatLng(8.486018, 124.655450), // Southwest corner of the bounding box
              LatLng(8.485803, 124.658071), // Northeast corner of the bounding box
            );

            // Check if the camera center is out of bounds
            final lat = camera.center.latitude;
            final lng = camera.center.longitude;

            // Constrain the camera center to stay within the bounds
            final clampedLat = lat.clamp(bounds.southWest.latitude, bounds.northEast.latitude);
            final clampedLng = lng.clamp(bounds.southWest.longitude, bounds.northEast.longitude);

            // Set the camera's new position if it's out of bounds
            if (lat != clampedLat || lng != clampedLng) {
              // Move the camera to the constrained position
              mapController.move(LatLng(clampedLat, clampedLng), camera.zoom);
            }
          },
          onTap: (tapPosition, latLng) {
              setState(() {
                selectedLocation = latLng;
                print(latLng);
              });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: selectedLocation,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_pin,
                  size: 40,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context, selectedLocation),
        child: const Icon(Icons.check),
      ),
    );
  }
}
