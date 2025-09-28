import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailer_app/features/auth/widgets/ImprovedTextField.dart';

void main() {
  group('ImprovedTextField Widget Tests', () {
    
    testWidgets('should render ImprovedTextField with basic properties', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      const labelText = 'Email Address';
      const prefixIcon = Icons.email_outlined;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImprovedTextField(
              controller: controller,
              labelText: labelText,
              prefixIcon: prefixIcon,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(labelText), findsOneWidget);
      expect(find.byIcon(prefixIcon), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(ImprovedTextField), findsOneWidget);
    });

    testWidgets('should show password visibility toggle for password fields', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      const labelText = 'Password';
      const prefixIcon = Icons.lock_outlined;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImprovedTextField(
              controller: controller,
              labelText: labelText,
              prefixIcon: prefixIcon,
              isPassword: true,
            ),
          ),
        ),
      );

      // Assert - Find visibility toggle icon
      final visibilityIcon = find.byIcon(Icons.visibility);
      expect(visibilityIcon, findsOneWidget);
      
      await tester.tap(visibilityIcon);
      await tester.pump();

      // Assert - Icon should change after tap
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('should not show visibility icon for non-password fields', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImprovedTextField(
              controller: controller,
              labelText: 'Email',
              prefixIcon: Icons.email,
              isPassword: false,
            ),
          ),
        ),
      );

      // Assert - no visibility icons should be present
      expect(find.byIcon(Icons.visibility), findsNothing);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });

    testWidgets('should validate input correctly with custom validator', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();
      const labelText = 'Email Address';
      const prefixIcon = Icons.email_outlined;

      String? validator(String? value) {
        if (value == null || value.isEmpty) {
          return 'Email is required';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Enter a valid email';
        }
        return null;
      }

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: ImprovedTextField(
                controller: controller,
                labelText: labelText,
                prefixIcon: prefixIcon,
                validator: validator,
              ),
            ),
          ),
        ),
      );

      // Test empty validation
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);

      // Test invalid email
      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);

      // Test valid email
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      final isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, isTrue);
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Enter a valid email'), findsNothing);
    });

    testWidgets('should handle focus and field submission correctly', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      final focusNode = FocusNode();
      bool fieldSubmitted = false;
      
      void onFieldSubmitted(String value) {
        fieldSubmitted = true;
      }

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImprovedTextField(
              controller: controller,
              labelText: 'Test Field',
              prefixIcon: Icons.text_fields,
              focusNode: focusNode,
              onFieldSubmitted: onFieldSubmitted,
            ),
          ),
        ),
      );

      // Focus the field and enter text
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'test input');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Assert
      expect(fieldSubmitted, isTrue);
      expect(controller.text, equals('test input'));
    });

    testWidgets('should accept different keyboard types', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImprovedTextField(
              controller: controller,
              labelText: 'Email Field',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      // Assert that the widget renders without errors
      expect(find.byType(ImprovedTextField), findsOneWidget);
      expect(find.text('Email Field'), findsOneWidget);
    });

    testWidgets('should display error message when validation fails', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      String? validator(String? value) {
        if (value == null || value.isEmpty) {
          return 'Required field';
        }
        return null;
      }

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: ImprovedTextField(
                controller: controller,
                labelText: 'Required Field',
                prefixIcon: Icons.star,
                validator: validator,
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();
      
      // Check that error text is displayed
      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('should handle text input correctly', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImprovedTextField(
              controller: controller,
              labelText: 'Test Input',
              prefixIcon: Icons.input,
            ),
          ),
        ),
      );

      // Enter text into the field
      const testText = 'Hello World';
      await tester.enterText(find.byType(TextFormField), testText);
      await tester.pump();

      // Assert
      expect(controller.text, equals(testText));
      expect(find.text(testText), findsOneWidget);
    });

    group('Integration Tests', () {
      testWidgets('should work correctly in a complete form', (WidgetTester tester) async {
        // Arrange
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        final formKey = GlobalKey<FormState>();
        bool formSubmitted = false;

        void submitForm() {
          if (formKey.currentState!.validate()) {
            formSubmitted = true;
          }
        }

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: Column(
                  children: [
                    ImprovedTextField(
                      controller: emailController,
                      labelText: 'Email',
                      prefixIcon: Icons.email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email required';
                        }
                        return null;
                      },
                    ),
                    ImprovedTextField(
                      controller: passwordController,
                      labelText: 'Password',
                      prefixIcon: Icons.lock,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password too short';
                        }
                        return null;
                      },
                    ),
                    ElevatedButton(
                      onPressed: submitForm,
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Test form validation
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(formSubmitted, isFalse);
        expect(find.text('Email required'), findsOneWidget);
        expect(find.text('Password too short'), findsOneWidget);

        // Fill out form correctly
        await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'validpassword');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert form submits successfully
        expect(formSubmitted, isTrue);
        expect(find.text('Email required'), findsNothing);
        expect(find.text('Password too short'), findsNothing);
      });
    });
  });
}