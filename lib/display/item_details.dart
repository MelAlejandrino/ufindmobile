import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../models/ticket_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'initial_chat.dart'; // Import your ChatScreen file
import 'package:intl/intl.dart';

class ItemDetailsPage extends StatelessWidget {
  final Ticket ticket;

  ItemDetailsPage({required this.ticket});

  // Helper function to parse the location string and extract latitude and longitude
  LatLng _parseLocation(String location) {
    final coordinates = location
        .split(',');

    double latitude = double.tryParse(coordinates[0].trim()) ?? 0.0;
    double longitude = double.tryParse(coordinates[1].trim()) ?? 0.0;

    return LatLng(latitude, longitude);
  }

  String formatDateTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime); // Parse the string to DateTime
      return DateFormat('EEEE, MMM d, yyyy • hh:mm a').format(parsedDate);
      // Example: "Friday, Dec 13, 2024 • 02:45 PM"
    } catch (e) {
      return 'Invalid date'; // Fallback if the parsing fails
    }
  }

  Future<String> _getSenderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_school_id') ?? ''; // Replace 'userId' with your actual preference key
  }

  @override
  Widget build(BuildContext context) {
    final latLng = _parseLocation(ticket.location);

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.name),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ticket.imageUrl.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: ticket.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                        if (ticket.status != 'lost')
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Apply blur
                              child: Container(
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: ticket.claimStatus.startsWith('turnover')
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey, // Disabled button color
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                  ),
                  child: Text(
                    ticket.claimStatus == 'turnover(guard)'
                        ? 'This item has been turned over to the Campus Security. Please visit their location at the Entrance Gate.'
                        : 'This item has been turned over to OSA. Please visit the Office of Student Affairs (OSA) for more information.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Text color
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                    : ElevatedButton(
                  onPressed: () async {
                    final senderId = await _getSenderId();
                    if (senderId.isNotEmpty) {
                      final senderPrefix = senderId.length > 10 ? senderId.substring(0, 10) : senderId;
                      final ticketPrefix = ticket.id.length > 10 ? ticket.id.substring(0, 10) : ticket.id;

                      if (senderPrefix == ticketPrefix) {
                        // Display a warning if the user tries to chat with themselves
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("You cannot chat with yourself."),
                          ),
                        );
                      } else {
                        // Navigate to the chat screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InitialChatPage(
                              userId: senderId,
                              receiverId: ticket.id.toString().substring(0, 10),  // Extract the first 10 digits
                              itemName: ticket.name,
                              itemType: ticket.status,
                            ),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Unable to fetch user ID")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.lightBlueAccent, // Text color
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Increased padding
                    elevation: 5, // Shadow effect for better visibility
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded corners
                    ),
                    minimumSize: const Size(40, 30), // Minimum size of the button
                  ),
                  child: Text(
                    ticket.status == 'lost' ? 'Contact Me' : 'Claim Now',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Details Section
                  Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 3, // Adds a subtle shadow effect
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.inventory, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Item Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'Item Name: ${ticket.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Item ID: ${ticket.id.substring(11)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            'Description: ${ticket.description}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            'Date & Time: ${formatDateTime(ticket.dateTime)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Contact Details Section
                  Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.contact_phone, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Contact Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'Name: ${ticket.fullName}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            'Number: ${ticket.contactNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            'Email: ${ticket.email}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
               const Text('Last Seen Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '${ticket.lastSeenLocation}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 300,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: latLng,
                      initialZoom: 18,
                      interactionOptions: const InteractionOptions(// Disable double-tap zoom
                        flags: InteractiveFlag.pinchZoom, // Enable zoom, disable other interactions like dragging
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latLng,
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
                ),
              const SizedBox(height: 16),
              // Add Chat Button

            ],
          ),
        ),
      ),
    );
  }
}
