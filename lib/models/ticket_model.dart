import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id; // Added ID field
  final String name;
  final String description;
  final String dateTime;
  final String fullName;
  final String contactNumber;
  final String email;
  final String location;
  final String imageUrl;
  final String status;
  final String studentId;
  final String ticket;
  late final String claimStatus;
  final String lastSeenLocation;




  Ticket({
    required this.id, // Include ID in constructor
    required this.name,
    required this.description,
    required this.dateTime,
    required this.fullName,
    required this.contactNumber,
    required this.email,
    required this.location,
    required this.imageUrl,
    required this.status,
    required this.ticket,
    required this.studentId,
    required this.claimStatus,
    required this.lastSeenLocation
  });

  factory Ticket.fromDocument(DocumentSnapshot doc) {
    return Ticket(
      id: doc.id, // Assign document ID
      name: doc['name'] ?? '',
      description: doc['description'] ?? '',
      dateTime: doc['dateTime'] ?? '',
      fullName: doc['fullName'] ?? '',
      contactNumber: doc['contactNumber'] ?? '',
      email: doc['email'] ?? '',
      location: doc['location'] ?? '',
      imageUrl: doc['imageUrl'] ?? '',
      status: doc['status'] ?? '',
      ticket: doc['ticket'] ?? '',
      studentId: doc['studentId'] ?? '',
      claimStatus: doc['claimStatus'] ?? '',
      lastSeenLocation: doc['lastSeenLocation'] ?? ''
    );
  }
}
