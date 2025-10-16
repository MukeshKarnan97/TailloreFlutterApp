import sqlite3
import os
from datetime import datetime

# Database path
db_path = r'C:\Users\mukes\Documents\tailor_app_db\tailor_app.db'

# Check if database exists
if not os.path.exists(db_path):
    print(f"❌ Database not found at: {db_path}")
    print("\nSearching in common locations...")
    
    # Try Android ADB
    print("\nAttempting to pull from Android device...")
    os.system('adb pull /data/user/0/com.example.tailer_app/databases/tailor_app.db tailor_app_android.db')
    
    if os.path.exists('tailor_app_android.db'):
        db_path = 'tailor_app_android.db'
        print(f"✅ Database pulled from Android: {db_path}")
    else:
        print("❌ Could not find or pull database")
        exit(1)

print("=" * 80)
print("  TAILOR TABLE DATA VIEWER")
print("=" * 80)
print(f"\nDatabase: {db_path}")
print(f"Size: {os.path.getsize(db_path):,} bytes")
print(f"Modified: {datetime.fromtimestamp(os.path.getmtime(db_path))}")
print()

# Connect to database
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

# Get table schema
print("=" * 80)
print("  TABLE SCHEMA")
print("=" * 80)
cursor.execute("PRAGMA table_info(tailor)")
columns = cursor.fetchall()

print(f"{'Column':<25} {'Type':<15} {'Not Null':<10} {'Default':<10} {'PK':<5}")
print("-" * 80)
for col in columns:
    print(f"{col['name']:<25} {col['type']:<15} {col['notnull']:<10} {str(col['dflt_value']):<10} {col['pk']:<5}")
print()

# Get record counts
print("=" * 80)
print("  STATISTICS")
print("=" * 80)
cursor.execute("SELECT COUNT(*) as total FROM tailor")
total = cursor.fetchone()['total']
print(f"Total Records: {total}")

cursor.execute("SELECT COUNT(*) as active FROM tailor WHERE is_active = 1")
active = cursor.fetchone()['active']
print(f"Active Users: {active}")

cursor.execute("SELECT COUNT(*) as inactive FROM tailor WHERE is_active = 0")
inactive = cursor.fetchone()['inactive']
print(f"Inactive Users: {inactive}")

cursor.execute("SELECT COUNT(*) as deleted FROM tailor WHERE is_deleted = 1")
deleted = cursor.fetchone()['deleted']
print(f"Deleted Users: {deleted}")
print()

# Get all records
print("=" * 80)
print("  ALL TAILOR TABLE DATA")
print("=" * 80)
print()

cursor.execute("SELECT * FROM tailor")
records = cursor.fetchall()

if not records:
    print("❌ No records found in tailor table")
else:
    for i, record in enumerate(records, 1):
        print(f"{'─' * 80}")
        print(f"  RECORD #{i}")
        print(f"{'─' * 80}")
        print(f"  ID: {record['id']}")
        print(f"  Unique ID: {record['unique_id']}")
        print(f"  Name: {record['name']}")
        print(f"  Shop Name: {record['shop_name']}")
        print(f"  Email: {record['email']}")
        print(f"  Phone: {record['phone']}")
        print(f"  Password Hash: {record['password_hash'][:50]}..." if record['password_hash'] and len(record['password_hash']) > 50 else f"  Password Hash: {record['password_hash']}")
        print(f"  Auth Provider: {record['auth_provider']}")
        print(f"  Address: {record['address']}")
        print(f"  Profile Image: {record['profile_image_path']}")
        print(f"  Is Active: {'✅ YES (1)' if record['is_active'] == 1 else '❌ NO (0)'}")
        print(f"  Is Deleted: {'🗑️ YES (1)' if record['is_deleted'] == 1 else '✅ NO (0)'}")
        print(f"  Created At: {record['created_at']}")
        print(f"  Updated At: {record['updated_at']}")
        print()

# Show active users
print("=" * 80)
print("  ACTIVE USERS ONLY (is_active = 1)")
print("=" * 80)
cursor.execute("SELECT * FROM tailor WHERE is_active = 1 AND is_deleted = 0")
active_users = cursor.fetchall()

if not active_users:
    print("❌ No active users found")
else:
    for i, user in enumerate(active_users, 1):
        print(f"{i}. {user['name']} ({user['email']}) - Created: {user['created_at']}")
print()

# Show inactive users
print("=" * 80)
print("  INACTIVE USERS (is_active = 0) - Pending OTP Verification")
print("=" * 80)
cursor.execute("SELECT * FROM tailor WHERE is_active = 0 AND is_deleted = 0")
inactive_users = cursor.fetchall()

if not inactive_users:
    print("✅ No inactive users (all users verified)")
else:
    for i, user in enumerate(inactive_users, 1):
        print(f"{i}. {user['name']} ({user['email']}) - Created: {user['created_at']}")
print()

# Close connection
conn.close()

print("=" * 80)
print("  END OF REPORT")
print("=" * 80)
