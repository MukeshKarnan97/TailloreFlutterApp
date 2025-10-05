@echo off
echo 💳 Payment Test Data Generator
echo ================================
echo.
echo This will create realistic payment records for existing orders.
echo.
echo What it creates:
echo   - Advance payments for most orders
echo   - Final payments for completed/delivered orders  
echo   - Random partial payments for some orders
echo   - Multiple payment methods (Cash, UPI, Card, Bank)
echo   - Realistic transaction references
echo   - Payment history spanning last 30 days
echo.
echo Prerequisites:
echo   - Must have existing orders in database
echo   - Run order test data first if needed
echo.
echo Login: admin1@gmail.com / Admin@123
echo.
pause
echo.
echo Starting payment data creation...
dart create_payment_test_data.dart
echo.
echo Payment test completed! Press any key to exit...
pause > nul