@echo off
echo 🔥 Running Order Status Test Data Generator...
echo.
echo This will insert sample orders with all status types:
echo   - pending (3 orders)
echo   - cutting (3 orders)  
echo   - stitching (3 orders)
echo   - in_progress (3 orders)
echo   - ready (3 orders)
echo   - completed (3 orders)
echo   - delivered (3 orders)
echo.
echo Total: 21 orders + 8 customers
echo Login: admin1@gmail.com / Admin@123
echo.
pause
echo.
echo Starting data insertion...
dart test_order_status_data.dart
echo.
echo Test completed! Press any key to exit...
pause > nul