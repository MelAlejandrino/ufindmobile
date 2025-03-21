import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // Function to send the email
  Future<void> _sendEmail() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String message = _messageController.text.trim();

    if (name.isEmpty || email.isEmpty || message.isEmpty) {
      // Show error if any of the fields are empty
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please fill out all fields before sending the message.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // SMTP configuration (using Gmail SMTP server for demonstration purposes)
    final smtpServer = gmail('joedavid1345@gmail.com', 'ogdo xldv yyla gley');  // Replace with your email credentials

    // Create a message
    final messageToSend = Message()
      ..from = const Address('joedavid1345@gmail.com', 'Support Email') // Replace with your email and name
      ..recipients.add('joedavid1345@gmail.com')  // Replace with the recipient's email
      ..subject = 'Contact Us Inquiry'
      ..text = 'Name: $name\nEmail: $email\nMessage: $message';

    try {
      await send(messageToSend, smtpServer);
      // print('Email sent: ${sendReport.toString()}');

      // Show a success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Your message has been sent successfully!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _nameController.clear();
                _emailController.clear();
                _messageController.clear();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // print('Error sending email: $e');

      // Show an error dialog if email could not be sent
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Something went wrong, please try again later.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us Now'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Feel free to reach out with any inquiries or feedback.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),

              // Contact Information Section
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Email: support@ufind.com', // Replace with your contact email
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 10),
              const Text(
                'Phone: +639295832504', // Replace with your contact number
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 10),
              const Text(
                'Office Hours: Mon - Fri, 9:00 AM - 5:00 PM',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 30),

              // Contact Form Section
              const Text(
                'Send Us a Message',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Your Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Your Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 20),

              // Button to send the email
              Center(
                child: ElevatedButton(
                  onPressed: _sendEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ), // Calls the send email function
                  child: const Text(
                    'Send Message',
                    style: TextStyle(color: Colors.white), // Set the text color to white
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
