import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import 'create_ticket.dart';
import 'item_details.dart';

class ItemsListPage extends StatefulWidget {
  @override
  _ItemsListPageState createState() => _ItemsListPageState();
}

class _ItemsListPageState extends State<ItemsListPage>
    with SingleTickerProviderStateMixin {
  String searchQuery = "";
  bool isSearching = false;
  String selectedFilter = "Time"; // Default sorting to 'Time' (Newest first)
  String typeFilter = "All"; // Default filter
  bool isDescending = true; // Default to descending (Newest first)
  Map<String, int> currentPage = {
    "lost": 1,
    "found": 1
  }; // Tracks the current page for each tab
  int itemsPerPage = 6; // Number of items per page

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // 2 tabs: Lost and Found
    _tabController.addListener(() {
      setState(() {
        // Reset search query and pagination when switching tabs
        searchQuery = "";
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Paginate items
  List<Ticket> paginateItems(List<Ticket> items, String status) {
    int startIndex = (currentPage[status]! - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    return items.sublist(
      startIndex,
      endIndex > items.length ? items.length : endIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
          decoration: const InputDecoration(
            hintText: "Search items...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.black12),
          ),
          style: const TextStyle(color: Colors.black54),
          autofocus: true,
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
        )
            : const Text("Items Feed"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) searchQuery = "";
                isSearching = !isSearching;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lost'),
            Tab(text: 'Found'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildItemsStream('lost'),
          buildItemsStream('found'),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            right: 0.0, // Set the left position (in pixels)
            bottom: 35.0, // Set the top position (in pixels)
            child: SizedBox(
              width: 50.0, // Set the desired width of the button
              height: 50.0, // Set the desired height of the button
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketDetailsPage(),
                    ),
                  );
                },
                backgroundColor: Colors.blueAccent,
                tooltip: 'Add New Ticket',
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),

    );
  }

  Widget buildItemsStream(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .where('status', isEqualTo: status)
          .orderBy("dateTime", descending: isDescending)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tickets = snapshot.data!.docs
            .map((doc) => Ticket.fromDocument(doc))
            .where((ticket) =>
        (ticket.name.toLowerCase().contains(searchQuery) ||
            ticket.description.toLowerCase().contains(searchQuery)))
            .toList();

        if (tickets.isEmpty) {
          return const Center(
            child: Text(
              "No items found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        // Paginate the items
        final paginatedTickets = paginateItems(tickets, status);

        return Stack(
          children: [
            Column(
              children: [
                Expanded( // Wrap the GridView with an Expanded widget
                  child: GridView.builder(
                    shrinkWrap: true,
                    // Allow GridView to take only as much space as it needs
                    physics: const NeverScrollableScrollPhysics(),
                    // Disable internal scrolling of GridView
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 1,
                                            mainAxisSpacing: 2,
                      childAspectRatio: 0.44,
                    ),
                    itemCount: paginatedTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = paginatedTickets[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ItemDetailsPage(ticket: ticket),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 3),
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ticket.imageUrl.isNotEmpty)
                                Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: ticket.imageUrl,
                                      fit: BoxFit.cover,
                                      height: double.infinity,
                                      width: double.infinity,
                                      placeholder: (context, url) =>
                                      const Center(
                                          child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                      const Icon(
                                          Icons.error, color: Colors.red),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticket.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      ticket.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: ticket.status == 'found'
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ticket.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      DateFormat('MM-dd-yyyy hh:mma').format(DateTime.parse(ticket.dateTime)),  // Convert string to DateTime and format to "12:30 PM"
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Fixed Pagination Controls at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildPaginationControls(tickets.length, status),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget buildPaginationControls(int totalItems, String status) {

    final totalPages = (totalItems / itemsPerPage).ceil();
    final currentStatusPage = currentPage[status]!;

    // Calculate the range of pages to show (maximum 5 buttons)
    final startPage = ((currentStatusPage - 1) ~/ 4) * 4 + 1;
    final endPage = (startPage + 4).clamp(1, totalPages);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (startPage > 1)
          TextButton(
            onPressed: () {
              setState(() {
                currentPage[status] = startPage - 1;
              });
            },
            child: const Text(
              'Previous',
              style: TextStyle(fontSize: 14),
            ),
          ),
        for (int i = startPage; i <= endPage; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                currentStatusPage == i ? Colors.blue : Colors.grey,
                minimumSize: const Size(30, 30),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(() {
                  currentPage[status] = i;
                });
              },
              child: Text(
                '$i',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (endPage < totalPages)
          TextButton(
            onPressed: () {
              setState(() {
                currentPage[status] = endPage + 1;
              });
            },
            child: const Text(
              'Next',
              style: TextStyle(fontSize: 14),
            ),
          ),
      ],
    );
  }
}