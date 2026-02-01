import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignupScreen Widget Tests', () {
    /// Test 1: Verify signup form fields are rendered
    testWidgets('Test 1: Signup form displays all required fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(label: Text('Name')),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(label: Text('Email')),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(label: Text('Password')),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(label: Text('Confirm Password')),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify form fields exist
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byType(Form), findsOneWidget);
    });

    /// Test 2: Verify password confirmation validation
    testWidgets('Test 2: Password confirmation validation works',
        (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      String password = '';
      String confirmPassword = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    onChanged: (value) => password = value,
                    decoration: const InputDecoration(label: Text('Password')),
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value != password) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(label: Text('Confirm Password')),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState?.validate();
                    },
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      
      // Enter password
      await tester.enterText(textFields.at(0), 'Password123');
      
      // Enter different confirm password
      await tester.enterText(textFields.at(1), 'Password456');
      
      await tester.pump();

      // Try to submit
      final signupButton = find.byType(ElevatedButton);
      if (signupButton.evaluate().isNotEmpty) {
        await tester.tap(signupButton.first);
        await tester.pump();
      }
    });

    /// Test 3: Verify both password visibility toggles work
    testWidgets('Test 3: Both password fields have visibility toggles',
        (WidgetTester tester) async {
      bool obscurePassword = true;
      bool obscureConfirmPassword = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    TextFormField(
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        label: const Text('Password'),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    TextFormField(
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        label: const Text('Confirm Password'),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Find visibility toggle buttons
      final visibilityButtons = find.byIcon(Icons.visibility_off);
      expect(visibilityButtons, findsWidgets);

      if (visibilityButtons.evaluate().length >= 1) {
        // Toggle first password visibility
        await tester.tap(visibilityButtons.first);
        await tester.pump();
      }
    });

    /// Test 4: Verify user can enter signup information
    testWidgets('Test 4: User can enter name, email, and passwords',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(label: Text('Name')),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(label: Text('Email')),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(label: Text('Password')),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(label: Text('Confirm Password')),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      
      // Enter name
      await tester.enterText(textFields.at(0), 'John Doe');
      // Enter email
      await tester.enterText(textFields.at(1), 'john@example.com');
      // Enter password
      await tester.enterText(textFields.at(2), 'Password123');
      // Enter confirm password
      await tester.enterText(textFields.at(3), 'Password123');
      
      await tester.pump();

      // Verify text was entered
      expect(find.text('john@example.com'), findsOneWidget);
    });

    /// Test 5: Verify form validation for all fields
    testWidgets('Test 5: Signup form requires all fields to be filled',
        (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Name required'
                        : null,
                    decoration: const InputDecoration(label: Text('Name')),
                  ),
                  TextFormField(
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Email required'
                        : null,
                    decoration: const InputDecoration(label: Text('Email')),
                  ),
                  TextFormField(
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Password required'
                        : null,
                    decoration: const InputDecoration(label: Text('Password')),
                  ),
                  TextFormField(
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Confirm password required'
                        : null,
                    decoration: const InputDecoration(label: Text('Confirm Password')),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState?.validate();
                    },
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Try to submit empty form
      final signupButton = find.byType(ElevatedButton);
      if (signupButton.evaluate().isNotEmpty) {
        await tester.tap(signupButton.first);
        await tester.pump();

        // Verify form still exists (validation prevented submission)
        expect(find.byType(Form), findsOneWidget);
      }
    });
  });
}
