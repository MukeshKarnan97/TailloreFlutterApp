# 📊 Tailor App - Complete Project Analysis & API Requirements

**Generated:** October 13, 2025  
**Project:** Flutter Tailor Management App  
**Backend:** Django REST API (To Be Created)

---

## 📱 PART 1: PROJECT ANALYSIS - WHAT'S MISSING

### ✅ **What's Already Implemented**

#### **1. Database Layer** (Local SQLite - Version 8)
- ✅ 11 Tables with proper foreign keys and cascade relationships
- ✅ Complete CRUD operations for all entities
- ✅ Data models: Customer, Order, Payment, Measurement, User
- ✅ Database service with migrations
- ✅ Indexes for performance optimization

#### **2. Authentication System**
- ✅ Local authentication with email/password
- ✅ Social auth (Google, Facebook, Apple) - UI only
- ✅ Session management with tokens
- ✅ User preferences storage
- ✅ Login history tracking
- ✅ Password reset flow (local)
- ⚠️ **MISSING**: Backend API integration for auth

#### **3. UI/UX Features**
- ✅ Splash screen with animations
- ✅ Onboarding flow (Home → User Agreement → Sign In)
- ✅ User agreement acceptance tracking
- ✅ Dashboard with analytics
- ✅ Customer management screens
- ✅ Order management (Add, Edit, View, Track status)
- ✅ Payment collection and history
- ✅ Measurement management
- ✅ Profile management
- ✅ Settings and preferences
- ✅ Multi-language support framework
- ✅ Theme system (Light/Dark)
- ✅ Custom branding (Teal theme, white logo)

#### **4. Business Logic**
- ✅ Order status workflow (Pending → Cutting → Stitching → Ready → Delivered)
- ✅ Payment tracking (Pending, Partial, Paid, Overdue)
- ✅ Measurement templates
- ✅ Customer profile management
- ✅ Order cancellation with refunds
- ✅ Notifications system (UI ready)
- ✅ Analytics and reports (local data)

---

### ❌ **What's MISSING - Critical Gaps**

#### **1. Cloud Backend Integration** ⚠️ CRITICAL
**Status:** Not implemented  
**Impact:** App works offline only, no data sync, no multi-device support

**Missing Components:**
- ❌ REST API endpoints
- ❌ API service layer in Flutter
- ❌ Data synchronization logic
- ❌ Conflict resolution for offline/online sync
- ❌ Backend authentication server
- ❌ Cloud database (PostgreSQL/MySQL)
- ❌ File storage for images (AWS S3/CloudFront)

**Current State:**
```dart
// Local DB only - no API calls
final dbService = LocalDatabaseService();
final customers = await dbService.getAllCustomers();
```

**Required State:**
```dart
// Hybrid: Try API first, fallback to local
final apiService = ApiService();
final customers = await apiService.getCustomers() ?? 
                  await dbService.getAllCustomers();
```

---

#### **2. Image Management** ⚠️ HIGH PRIORITY
**Status:** Partially implemented  
**Impact:** Cannot store order design images, customer photos

**Missing:**
- ❌ Image upload to cloud storage
- ❌ Image compression before upload
- ❌ Image gallery for orders
- ❌ Profile picture upload
- ⚠️ Design images stored as local paths only (not synced)

**Current Schema:**
```sql
orders.design_image_url TEXT  -- Local path only
orders.image_path_1 TEXT      -- Not being used
orders.image_path_2 TEXT      -- Not being used
```

**Required:**
- Cloud URLs for images
- Image processing pipeline
- CDN for fast delivery

---

#### **3. Real-time Features** 🔴 NOT IMPLEMENTED
**Status:** Not available  
**Impact:** No live updates, no push notifications

**Missing:**
- ❌ WebSocket/Firebase connection
- ❌ Real-time order status updates
- ❌ Push notifications (payment received, order ready)
- ❌ In-app messaging
- ❌ Live analytics dashboard

**Current:** Manual refresh required  
**Required:** Auto-update when data changes on server

---

#### **4. Multi-User & Multi-Device Support** 🔴 NOT IMPLEMENTED
**Status:** Single device only  
**Impact:** Cannot use app on multiple devices

**Missing:**
- ❌ Cloud data storage
- ❌ Device registration
- ❌ Session management across devices
- ❌ Data sync between devices
- ❌ Multi-tailor shop support (currently single tailor)

**Current:** One device, one tailor  
**Required:** Multiple devices, multiple tailors per shop

---

#### **5. Backup & Restore** ⚠️ PARTIAL
**Status:** Local database backup only  
**Impact:** Data loss if device is lost/damaged

**Current:**
```dart
// Local backup to device storage only
await dbService.backupDatabase();
```

**Missing:**
- ❌ Cloud backup to server
- ❌ Automated daily backups
- ❌ Cross-device restore
- ❌ Backup encryption
- ❌ Backup versioning

---

#### **6. Analytics & Reporting** ⚠️ BASIC ONLY
**Status:** Local analytics implemented  
**Impact:** Limited insights, no historical trends

**Current Features:**
- ✅ Daily/weekly/monthly revenue (local)
- ✅ Payment method breakdown
- ✅ Order status distribution
- ✅ Top customers (local data)

**Missing:**
- ❌ Year-over-year comparison
- ❌ Business growth metrics
- ❌ Customer retention analysis
- ❌ Export to PDF/Excel
- ❌ Email reports
- ❌ Dashboard widgets

---

#### **7. Payment Gateway Integration** 🔴 NOT IMPLEMENTED
**Status:** Manual payment tracking only  
**Impact:** No online payments, manual entry required

**Missing:**
- ❌ Razorpay/PayU/Stripe integration
- ❌ Online payment links
- ❌ Payment QR codes
- ❌ UPI payment integration
- ❌ Auto-reconciliation of payments

**Current:** Manual cash/card tracking  
**Required:** Auto-capture from payment gateways

---

#### **8. SMS/Email Notifications** 🔴 NOT IMPLEMENTED
**Status:** In-app UI only  
**Impact:** Customers not notified outside app

**Missing:**
- ❌ SMS service (Twilio/AWS SNS)
- ❌ Email service (SendGrid/AWS SES)
- ❌ WhatsApp Business API
- ❌ Order ready notifications
- ❌ Payment reminders
- ❌ Delivery reminders

---

#### **9. Security Features** ⚠️ BASIC ONLY
**Status:** Local auth only  
**Impact:** Limited security, no enterprise features

**Current:**
- ✅ Local password hashing
- ✅ Session tokens (local)
- ✅ Basic input validation

**Missing:**
- ❌ JWT authentication with server
- ❌ OAuth 2.0 implementation
- ❌ Two-factor authentication (2FA)
- ❌ Rate limiting
- ❌ API key management
- ❌ Encryption at rest
- ❌ Audit logging to server
- ❌ RBAC (Role-Based Access Control)

---

#### **10. Performance Optimizations** ⚠️ NEEDS IMPROVEMENT
**Missing:**
- ❌ Image lazy loading
- ❌ Pagination for large lists
- ❌ Caching strategy
- ❌ Background sync
- ❌ Offline queue for API calls
- ❌ Database query optimization
- ❌ Memory leak detection

---

### 🎯 **Priority Matrix**

| Feature | Priority | Impact | Complexity | Timeline |
|---------|----------|--------|------------|----------|
| Cloud Backend API | 🔴 CRITICAL | Very High | High | 4-6 weeks |
| Image Upload/Storage | 🔴 HIGH | High | Medium | 2-3 weeks |
| Data Sync Logic | 🔴 HIGH | Very High | High | 3-4 weeks |
| Push Notifications | 🟡 MEDIUM | Medium | Medium | 2-3 weeks |
| Payment Gateway | 🟡 MEDIUM | Medium | Medium | 2-3 weeks |
| Multi-device Support | 🟡 MEDIUM | High | High | 3-4 weeks |
| SMS/Email | 🟢 LOW | Low | Low | 1-2 weeks |
| Analytics Export | 🟢 LOW | Low | Low | 1 week |
| 2FA Security | 🟢 LOW | Medium | Medium | 1-2 weeks |
| Real-time Updates | 🟡 MEDIUM | Medium | High | 3-4 weeks |

---

## 🚀 PART 2: DJANGO REST API - COMPLETE DOCUMENTATION

### **Architecture Overview**

```
┌─────────────────┐      HTTPS/REST       ┌──────────────────┐
│                 │ ───────────────────► │                  │
│  Flutter App    │                       │  Django REST API │
│  (Frontend)     │ ◄─────────────────── │  (Backend)       │
│                 │      JSON Response    │                  │
└─────────────────┘                       └──────────────────┘
        │                                          │
        │                                          │
        ▼                                          ▼
  ┌──────────┐                            ┌─────────────┐
  │  SQLite  │                            │ PostgreSQL  │
  │  Local   │                            │   Cloud     │
  │  Cache   │                            │  Database   │
  └──────────┘                            └─────────────┘
                                                  │
                                                  ▼
                                          ┌──────────────┐
                                          │   AWS S3     │
                                          │ Image Storage│
                                          └──────────────┘
```

---

### **🔧 Technology Stack**

#### **Backend Framework**
- **Django 5.0+** - Web framework
- **Django REST Framework 3.14+** - API layer
- **PostgreSQL 15+** - Primary database
- **Redis** - Caching & sessions
- **Celery** - Background tasks
- **AWS S3** - File storage
- **CloudFront** - CDN

#### **Authentication**
- **djangorestframework-simplejwt** - JWT tokens
- **django-allauth** - Social auth
- **dj-rest-auth** - REST auth endpoints

#### **Additional Packages**
```python
# requirements.txt
Django==5.0.0
djangorestframework==3.14.0
psycopg2-binary==2.9.9
django-cors-headers==4.3.1
djangorestframework-simplejwt==5.3.1
dj-rest-auth==5.0.2
django-allauth==0.57.0
Pillow==10.1.0
django-storages==1.14.2
boto3==1.34.0
celery==5.3.4
redis==5.0.1
python-decouple==3.8
gunicorn==21.2.0
whitenoise==6.6.0
drf-spectacular==0.27.0  # API documentation
django-filter==23.5
```

---

### **📁 Project Structure**

```
tailor_backend/
├── manage.py
├── requirements.txt
├── .env
├── .env.example
├── Dockerfile
├── docker-compose.yml
├── README.md
│
├── config/                          # Django project settings
│   ├── __init__.py
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py                 # Base settings
│   │   ├── development.py          # Dev environment
│   │   ├── production.py           # Prod environment
│   │   └── testing.py              # Test environment
│   ├── urls.py                     # Main URL routing
│   ├── wsgi.py
│   └── asgi.py                     # For WebSockets
│
├── apps/                            # Django apps
│   │
│   ├── accounts/                    # User management
│   │   ├── __init__.py
│   │   ├── models.py               # User, Profile
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── permissions.py
│   │   ├── signals.py
│   │   └── tests/
│   │
│   ├── tailors/                     # Tailor/Shop management
│   │   ├── models.py               # Tailor, Shop
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   └── tests/
│   │
│   ├── customers/                   # Customer management
│   │   ├── models.py               # Customer
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── filters.py
│   │   └── tests/
│   │
│   ├── measurements/                # Measurement management
│   │   ├── models.py               # Measurement
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   └── tests/
│   │
│   ├── orders/                      # Order management
│   │   ├── models.py               # Order, OrderCancellation
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── filters.py
│   │   ├── tasks.py                # Celery tasks
│   │   └── tests/
│   │
│   ├── payments/                    # Payment management
│   │   ├── models.py               # Payment
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── services/               # Payment gateway integrations
│   │   │   ├── razorpay.py
│   │   │   ├── stripe.py
│   │   │   └── payu.py
│   │   └── tests/
│   │
│   ├── notifications/               # Notification system
│   │   ├── models.py               # Notification
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── services/
│   │   │   ├── push.py             # FCM/APNs
│   │   │   ├── sms.py              # Twilio
│   │   │   ├── email.py            # SendGrid
│   │   │   └── whatsapp.py         # WhatsApp Business
│   │   └── tests/
│   │
│   ├── analytics/                   # Analytics & Reports
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   └── tasks.py
│   │
│   └── core/                        # Shared utilities
│       ├── models.py               # Abstract base models
│       ├── mixins.py
│       ├── exceptions.py
│       ├── pagination.py
│       ├── permissions.py
│       ├── utils.py
│       └── middleware.py
│
├── media/                           # User uploaded files
│   ├── orders/
│   ├── customers/
│   └── temp/
│
└── static/                          # Static files
    ├── admin/
    └── api/
```

---

### **📊 Database Models (Django)**

#### **1. Tailor Model**

```python
# apps/tailors/models.py
from django.db import models
from django.contrib.auth import get_user_model
from apps.core.models import TimestampedModel

User = get_user_model()

class Tailor(TimestampedModel):
    """Tailor/Shop profile"""
    
    unique_id = models.CharField(max_length=50, unique=True, db_index=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='tailor_profile')
    shop_name = models.CharField(max_length=200)
    owner_name = models.CharField(max_length=200)
    phone = models.CharField(max_length=20)
    email = models.EmailField(unique=True)
    address = models.TextField()
    gst_number = models.CharField(max_length=15, blank=True, null=True)
    logo = models.ImageField(upload_to='tailors/logos/', blank=True, null=True)
    subscription_plan = models.CharField(
        max_length=20,
        choices=[('free', 'Free'), ('pro', 'Pro'), ('enterprise', 'Enterprise')],
        default='free'
    )
    is_active = models.BooleanField(default=True)
    is_deleted = models.BooleanField(default=False)
    
    class Meta:
        db_table = 'tailor'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['unique_id']),
            models.Index(fields=['email']),
        ]
    
    def __str__(self):
        return f"{self.shop_name} ({self.unique_id})"
```

---

#### **2. Customer Model**

```python
# apps/customers/models.py
from django.db import models
from apps.core.models import TimestampedModel

class Customer(TimestampedModel):
    """Customer profile"""
    
    unique_id = models.CharField(max_length=50, unique=True, db_index=True)
    tailor = models.ForeignKey('tailors.Tailor', on_delete=models.CASCADE, related_name='customers')
    name = models.CharField(max_length=200)
    gender = models.CharField(
        max_length=10,
        choices=[('Male', 'Male'), ('Female', 'Female'), ('Other', 'Other')],
        blank=True
    )
    phone = models.CharField(max_length=20)
    email = models.EmailField(blank=True, null=True)
    address = models.TextField()
    notes = models.TextField(blank=True)
    profile_image = models.ImageField(upload_to='customers/profiles/', blank=True, null=True)
    is_deleted = models.BooleanField(default=False)
    
    class Meta:
        db_table = 'customer'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['tailor', 'is_deleted']),
            models.Index(fields=['phone']),
            models.Index(fields=['unique_id']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.phone})"
```

---

#### **3. Measurement Model**

```python
# apps/measurements/models.py
from django.db import models
from apps.core.models import TimestampedModel

class Measurement(TimestampedModel):
    """Customer measurements"""
    
    unique_id = models.CharField(max_length=50, unique=True, db_index=True)
    customer = models.ForeignKey('customers.Customer', on_delete=models.CASCADE, related_name='measurements')
    dress_type = models.CharField(max_length=100)  # Shirt, Pant, Kurta, etc.
    measurements = models.JSONField()  # {"chest": 40, "waist": 32, ...}
    notes = models.TextField(blank=True)
    is_deleted = models.BooleanField(default=False)
    
    class Meta:
        db_table = 'measurement'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['customer', 'dress_type']),
            models.Index(fields=['unique_id']),
        ]
    
    def __str__(self):
        return f"{self.customer.name} - {self.dress_type}"
```

---

#### **4. Order Model**

```python
# apps/orders/models.py
from django.db import models
from apps.core.models import TimestampedModel

class Order(TimestampedModel):
    """Customer orders"""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('cutting', 'Cutting'),
        ('stitching', 'Stitching'),
        ('ready', 'Ready'),
        ('delivered', 'Delivered'),
    ]
    
    PAYMENT_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('partial', 'Partial'),
        ('paid', 'Paid'),
        ('overdue', 'Overdue'),
    ]
    
    unique_id = models.CharField(max_length=50, unique=True, db_index=True)
    customer = models.ForeignKey('customers.Customer', on_delete=models.CASCADE, related_name='orders')
    tailor = models.ForeignKey('tailors.Tailor', on_delete=models.CASCADE, related_name='orders')
    measurement = models.ForeignKey('measurements.Measurement', on_delete=models.SET_NULL, 
                                   null=True, blank=True, related_name='orders')
    
    service_type = models.CharField(max_length=100)  # Dress type
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='pending')
    
    delivery_date = models.DateTimeField()
    notes = models.TextField(blank=True)
    
    # Images
    design_image = models.ImageField(upload_to='orders/designs/', blank=True, null=True)
    image_1 = models.ImageField(upload_to='orders/images/', blank=True, null=True)
    image_2 = models.ImageField(upload_to='orders/images/', blank=True, null=True)
    
    # Financial
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    advance_paid = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    balance_amount = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Measurements (JSON for flexibility)
    measurements = models.JSONField(blank=True, null=True)
    
    is_deleted = models.BooleanField(default=False)
    
    class Meta:
        db_table = 'orders'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['tailor', 'status', 'is_deleted']),
            models.Index(fields=['customer', 'is_deleted']),
            models.Index(fields=['delivery_date']),
            models.Index(fields=['payment_status']),
            models.Index(fields=['unique_id']),
        ]
    
    def __str__(self):
        return f"Order {self.unique_id} - {self.customer.name}"
    
    def save(self, *args, **kwargs):
        # Auto-calculate balance
        self.balance_amount = self.total_amount - self.advance_paid
        super().save(*args, **kwargs)


class OrderCancellation(TimestampedModel):
    """Track cancelled orders with reasons"""
    
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='cancellation')
    reason = models.CharField(max_length=200)
    custom_reason = models.TextField(blank=True)
    cancelled_by = models.CharField(max_length=200)
    cancelled_at = models.DateTimeField(auto_now_add=True)
    refund_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    refund_status = models.CharField(max_length=50, default='not_applicable')
    refund_notes = models.TextField(blank=True)
    
    class Meta:
        db_table = 'order_cancellations'
```

---

#### **5. Payment Model**

```python
# apps/payments/models.py
from django.db import models
from apps.core.models import TimestampedModel

class Payment(TimestampedModel):
    """Payment records"""
    
    METHOD_CHOICES = [
        ('cash', 'Cash'),
        ('card', 'Card'),
        ('upi', 'UPI'),
        ('bank_transfer', 'Bank Transfer'),
        ('online', 'Online Gateway'),
    ]
    
    unique_id = models.CharField(max_length=50, unique=True, db_index=True)
    order = models.ForeignKey('orders.Order', on_delete=models.CASCADE, related_name='payments')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    method = models.CharField(max_length=20, choices=METHOD_CHOICES, default='cash')
    transaction_id = models.CharField(max_length=200, blank=True)
    notes = models.TextField(blank=True)
    paid_on = models.DateTimeField()
    is_deleted = models.BooleanField(default=False)
    
    # Payment gateway metadata
    gateway_response = models.JSONField(blank=True, null=True)
    
    class Meta:
        db_table = 'payment'
        ordering = ['-paid_on']
        indexes = [
            models.Index(fields=['order', 'is_deleted']),
            models.Index(fields=['method']),
            models.Index(fields=['paid_on']),
            models.Index(fields=['unique_id']),
        ]
    
    def __str__(self):
        return f"Payment {self.unique_id} - ₹{self.amount}"
```

---

#### **6. Notification Model**

```python
# apps/notifications/models.py
from django.db import models
from apps.core.models import TimestampedModel

class Notification(TimestampedModel):
    """In-app and push notifications"""
    
    TYPE_CHOICES = [
        ('order_ready', 'Order Ready'),
        ('payment_received', 'Payment Received'),
        ('delivery_reminder', 'Delivery Reminder'),
        ('payment_reminder', 'Payment Reminder'),
        ('system', 'System'),
    ]
    
    user = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    data = models.JSONField(blank=True, null=True)  # Extra metadata
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        db_table = 'notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_read']),
            models.Index(fields=['type']),
        ]
```

---

### **🔗 API Endpoints Documentation**

#### **Base URL:** `https://api.yourapp.com/api/v1/`

---

### **Authentication Endpoints**

```python
# apps/accounts/urls.py
from django.urls import path
from . import views

urlpatterns = [
    # Registration & Login
    path('auth/register/', views.RegisterView.as_view(), name='register'),
    path('auth/login/', views.LoginView.as_view(), name='login'),
    path('auth/logout/', views.LogoutView.as_view(), name='logout'),
    path('auth/refresh/', views.RefreshTokenView.as_view(), name='refresh_token'),
    
    # Password Management
    path('auth/password/reset/', views.PasswordResetView.as_view(), name='password_reset'),
    path('auth/password/reset/confirm/', views.PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    path('auth/password/change/', views.ChangePasswordView.as_view(), name='change_password'),
    
    # Social Auth
    path('auth/google/', views.GoogleLoginView.as_view(), name='google_login'),
    path('auth/facebook/', views.FacebookLoginView.as_view(), name='facebook_login'),
    path('auth/apple/', views.AppleLoginView.as_view(), name='apple_login'),
    
    # User Profile
    path('users/me/', views.CurrentUserView.as_view(), name='current_user'),
    path('users/me/profile/', views.ProfileUpdateView.as_view(), name='update_profile'),
    path('users/me/preferences/', views.PreferencesView.as_view(), name='user_preferences'),
]
```

#### **Example: Register**
```http
POST /api/v1/auth/register/
Content-Type: application/json

{
  "email": "tailor@example.com",
  "password": "SecurePass123!",
  "password_confirm": "SecurePass123!",
  "shop_name": "Elegant Tailors",
  "owner_name": "Rajesh Kumar",
  "phone": "+919876543210"
}

Response 201:
{
  "user": {
    "id": 1,
    "email": "tailor@example.com",
    "tailor_profile": {
      "unique_id": "TAIL1234567",
      "shop_name": "Elegant Tailors",
      "owner_name": "Rajesh Kumar",
      "phone": "+919876543210"
    }
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
}
```

#### **Example: Login**
```http
POST /api/v1/auth/login/
Content-Type: application/json

{
  "email": "tailor@example.com",
  "password": "SecurePass123!"
}

Response 200:
{
  "user": {
    "id": 1,
    "email": "tailor@example.com",
    "tailor_profile": {...}
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
}
```

---

### **Customer Endpoints**

```python
# apps/customers/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register('', views.CustomerViewSet, basename='customer')

urlpatterns = [
    path('', include(router.urls)),
    # Additional custom endpoints
    path('<str:unique_id>/orders/', views.CustomerOrdersView.as_view(), name='customer_orders'),
    path('<str:unique_id>/measurements/', views.CustomerMeasurementsView.as_view(), name='customer_measurements'),
    path('<str:unique_id>/payments/', views.CustomerPaymentsView.as_view(), name='customer_payments'),
]
```

#### **CRUD Operations**

```http
# Create Customer
POST /api/v1/customers/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "name": "Priya Sharma",
  "gender": "Female",
  "phone": "+919876543211",
  "email": "priya@example.com",
  "address": "456 Brigade Road, Bangalore"
}

Response 201:
{
  "unique_id": "CUST5A7B9C2",
  "tailor": "TAIL1234567",
  "name": "Priya Sharma",
  "gender": "Female",
  "phone": "+919876543211",
  "email": "priya@example.com",
  "address": "456 Brigade Road, Bangalore",
  "created_at": "2025-10-13T10:30:00Z",
  "updated_at": "2025-10-13T10:30:00Z"
}
```

```http
# List Customers (with pagination & filters)
GET /api/v1/customers/?page=1&page_size=20&search=priya&gender=Female
Authorization: Bearer {access_token}

Response 200:
{
  "count": 45,
  "next": "https://api.yourapp.com/api/v1/customers/?page=2",
  "previous": null,
  "results": [
    {
      "unique_id": "CUST5A7B9C2",
      "name": "Priya Sharma",
      "phone": "+919876543211",
      "total_orders": 12,
      "pending_balance": 2500.00,
      "last_order_date": "2025-10-10T14:30:00Z"
    },
    ...
  ]
}
```

```http
# Get Customer Details
GET /api/v1/customers/CUST5A7B9C2/
Authorization: Bearer {access_token}

Response 200:
{
  "unique_id": "CUST5A7B9C2",
  "tailor": "TAIL1234567",
  "name": "Priya Sharma",
  "gender": "Female",
  "phone": "+919876543211",
  "email": "priya@example.com",
  "address": "456 Brigade Road, Bangalore",
  "profile_image": "https://cdn.yourapp.com/customers/priya.jpg",
  "total_orders": 12,
  "total_spent": 45000.00,
  "pending_balance": 2500.00,
  "created_at": "2025-01-15T09:00:00Z",
  "updated_at": "2025-10-13T10:30:00Z"
}
```

```http
# Update Customer
PATCH /api/v1/customers/CUST5A7B9C2/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "email": "priya.new@example.com",
  "address": "789 MG Road, Bangalore"
}

Response 200:
{
  "unique_id": "CUST5A7B9C2",
  "email": "priya.new@example.com",
  "address": "789 MG Road, Bangalore",
  ...
}
```

```http
# Delete Customer (soft delete)
DELETE /api/v1/customers/CUST5A7B9C2/
Authorization: Bearer {access_token}

Response 204: No Content
```

---

### **Order Endpoints**

```python
# apps/orders/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register('', views.OrderViewSet, basename='order')

urlpatterns = [
    path('', include(router.urls)),
    path('<str:unique_id>/status/', views.UpdateOrderStatusView.as_view(), name='update_status'),
    path('<str:unique_id>/cancel/', views.CancelOrderView.as_view(), name='cancel_order'),
    path('<str:unique_id>/images/', views.OrderImagesView.as_view(), name='order_images'),
    path('stats/dashboard/', views.OrderDashboardStatsView.as_view(), name='order_stats'),
]
```

#### **Order Operations**

```http
# Create Order
POST /api/v1/orders/
Authorization: Bearer {access_token}
Content-Type: multipart/form-data

{
  "customer_id": "CUST5A7B9C2",
  "measurement_id": "MEAS1A2B3C4",
  "service_type": "Shirt",
  "delivery_date": "2025-10-20T17:00:00Z",
  "total_amount": 1500.00,
  "advance_paid": 500.00,
  "notes": "White collar, blue buttons",
  "design_image": <file>,
  "measurements": {
    "chest": 40,
    "waist": 34,
    "sleeve": 24
  }
}

Response 201:
{
  "unique_id": "ORD8X9Y0Z1",
  "customer": {
    "unique_id": "CUST5A7B9C2",
    "name": "Priya Sharma",
    "phone": "+919876543211"
  },
  "service_type": "Shirt",
  "status": "pending",
  "payment_status": "partial",
  "delivery_date": "2025-10-20T17:00:00Z",
  "total_amount": "1500.00",
  "advance_paid": "500.00",
  "balance_amount": "1000.00",
  "design_image": "https://cdn.yourapp.com/orders/designs/abc123.jpg",
  "created_at": "2025-10-13T11:00:00Z"
}
```

```http
# Update Order Status
PATCH /api/v1/orders/ORD8X9Y0Z1/status/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "status": "stitching"
}

Response 200:
{
  "unique_id": "ORD8X9Y0Z1",
  "status": "stitching",
  "updated_at": "2025-10-13T12:00:00Z"
}
```

```http
# List Orders with Filters
GET /api/v1/orders/?status=pending&payment_status=partial&delivery_date_from=2025-10-13&delivery_date_to=2025-10-31
Authorization: Bearer {access_token}

Response 200:
{
  "count": 23,
  "results": [
    {
      "unique_id": "ORD8X9Y0Z1",
      "customer_name": "Priya Sharma",
      "service_type": "Shirt",
      "status": "pending",
      "payment_status": "partial",
      "delivery_date": "2025-10-20T17:00:00Z",
      "balance_amount": "1000.00"
    },
    ...
  ]
}
```

---

### **Payment Endpoints**

```http
# Create Payment
POST /api/v1/payments/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "order_id": "ORD8X9Y0Z1",
  "amount": 500.00,
  "method": "upi",
  "transaction_id": "UPI123456789",
  "notes": "Partial payment via Google Pay"
}

Response 201:
{
  "unique_id": "PAY4D5E6F7",
  "order": "ORD8X9Y0Z1",
  "amount": "500.00",
  "method": "upi",
  "transaction_id": "UPI123456789",
  "paid_on": "2025-10-13T14:30:00Z",
  "order_balance_updated": "500.00"
}
```

```http
# Payment History
GET /api/v1/payments/?order_id=ORD8X9Y0Z1
Authorization: Bearer {access_token}

Response 200:
{
  "count": 2,
  "total_amount": "1000.00",
  "results": [
    {
      "unique_id": "PAY4D5E6F7",
      "amount": "500.00",
      "method": "upi",
      "paid_on": "2025-10-13T14:30:00Z"
    },
    {
      "unique_id": "PAY1A2B3C4",
      "amount": "500.00",
      "method": "cash",
      "paid_on": "2025-10-13T11:00:00Z"
    }
  ]
}
```

---

### **Measurement Endpoints**

```http
# Create Measurement
POST /api/v1/measurements/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "customer_id": "CUST5A7B9C2",
  "dress_type": "Shirt",
  "measurements": {
    "chest": 40,
    "waist": 34,
    "shoulder": 18,
    "sleeve": 24,
    "length": 30
  },
  "notes": "Regular fit preference"
}

Response 201:
{
  "unique_id": "MEAS7G8H9I",
  "customer": "CUST5A7B9C2",
  "dress_type": "Shirt",
  "measurements": {
    "chest": 40,
    "waist": 34,
    "shoulder": 18,
    "sleeve": 24,
    "length": 30
  },
  "created_at": "2025-10-13T10:00:00Z"
}
```

---

### **Analytics Endpoints**

```http
# Dashboard Analytics
GET /api/v1/analytics/dashboard/?period=monthly&start_date=2025-10-01&end_date=2025-10-31
Authorization: Bearer {access_token}

Response 200:
{
  "period": "monthly",
  "date_range": {
    "start": "2025-10-01",
    "end": "2025-10-31"
  },
  "revenue": {
    "total": 125000.00,
    "growth": 15.5,
    "by_payment_method": {
      "cash": 60000.00,
      "upi": 45000.00,
      "card": 20000.00
    }
  },
  "orders": {
    "total": 85,
    "by_status": {
      "pending": 12,
      "cutting": 8,
      "stitching": 25,
      "ready": 15,
      "delivered": 25
    },
    "growth": 12.3
  },
  "customers": {
    "total": 45,
    "new": 8,
    "top_customers": [
      {
        "unique_id": "CUST5A7B9C2",
        "name": "Priya Sharma",
        "total_spent": 15000.00,
        "total_orders": 12
      },
      ...
    ]
  },
  "pending_balance": 25000.00
}
```

---

### **Image Upload Endpoint**

```http
# Upload Order Images
POST /api/v1/orders/ORD8X9Y0Z1/images/
Authorization: Bearer {access_token}
Content-Type: multipart/form-data

{
  "image_1": <file>,
  "image_2": <file>
}

Response 200:
{
  "unique_id": "ORD8X9Y0Z1",
  "image_1": "https://cdn.yourapp.com/orders/images/order1_img1.jpg",
  "image_2": "https://cdn.yourapp.com/orders/images/order1_img2.jpg"
}
```

---

### **🔐 Authentication Flow**

#### **JWT Token Authentication**

```python
# config/settings/base.py
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
}

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
}
```

#### **Flutter Integration**

```dart
// lib/data/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://api.yourapp.com/api/v1';
  String? _accessToken;
  String? _refreshToken;
  
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['tokens']['access'];
      _refreshToken = data['tokens']['refresh'];
      
      // Save tokens securely
      await _saveTokens(_accessToken!, _refreshToken!);
      
      return data;
    } else {
      throw Exception('Login failed');
    }
  }
  
  // Authenticated request with auto token refresh
  Future<http.Response> get(String endpoint) async {
    var response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );
    
    // If token expired, refresh and retry
    if (response.statusCode == 401) {
      await _refreshAccessToken();
      response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );
    }
    
    return response;
  }
  
  // Refresh access token
  Future<void> _refreshAccessToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': _refreshToken}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access'];
      await _saveTokens(_accessToken!, _refreshToken!);
    } else {
      // Refresh token expired, logout user
      await logout();
      throw Exception('Session expired');
    }
  }
}
```

---

### **📤 Data Synchronization Strategy**

#### **Sync Architecture**

```dart
// lib/data/services/sync_service.dart
class SyncService {
  final ApiService _apiService = ApiService();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  
  // Sync all data
  Future<void> fullSync() async {
    Logger.info('SyncService', 'Starting full sync');
    
    try {
      // 1. Push local changes to server
      await _pushLocalChanges();
      
      // 2. Pull server changes to local
      await _pullServerChanges();
      
      Logger.info('SyncService', 'Full sync completed successfully');
    } catch (e) {
      Logger.error('SyncService', 'Sync failed', error: e);
      throw e;
    }
  }
  
  // Push local changes
  Future<void> _pushLocalChanges() async {
    // Get all locally modified records since last sync
    final lastSyncTime = await _getLastSyncTime();
    
    // Push customers
    final localCustomers = await _dbService.getModifiedCustomersSince(lastSyncTime);
    for (final customer in localCustomers) {
      await _apiService.post('/customers/', customer.toMap());
    }
    
    // Push orders
    final localOrders = await _dbService.getModifiedOrdersSince(lastSyncTime);
    for (final order in localOrders) {
      await _apiService.post('/orders/', order.toMap());
    }
    
    // Push payments
    final localPayments = await _dbService.getModifiedPaymentsSince(lastSyncTime);
    for (final payment in localPayments) {
      await _apiService.post('/payments/', payment.toMap());
    }
  }
  
  // Pull server changes
  Future<void> _pullServerChanges() async {
    final lastSyncTime = await _getLastSyncTime();
    
    // Pull customers
    final response = await _apiService.get('/customers/?modified_since=$lastSyncTime');
    final customers = jsonDecode(response.body)['results'];
    for (final customerData in customers) {
      final customer = Customer.fromMap(customerData);
      await _dbService.insertOrUpdateCustomer(customer);
    }
    
    // Pull orders, payments, etc.
    // ... similar logic
    
    // Update last sync time
    await _setLastSyncTime(DateTime.now());
  }
  
  // Conflict resolution
  Future<void> _resolveConflict(String entityType, Map<String, dynamic> local, Map<String, dynamic> server) async {
    // Strategy: Server wins (can be customized)
    final localUpdatedAt = DateTime.parse(local['updated_at']);
    final serverUpdatedAt = DateTime.parse(server['updated_at']);
    
    if (serverUpdatedAt.isAfter(localUpdatedAt)) {
      // Server is newer, update local
      Logger.info('SyncService', 'Conflict resolved: Server wins for $entityType');
      return server;
    } else {
      // Local is newer, push to server
      Logger.info('SyncService', 'Conflict resolved: Local wins for $entityType');
      await _apiService.put('/$entityType/${local['unique_id']}/', local);
    }
  }
}
```

---

### **🚀 Deployment Guide**

#### **1. Environment Setup**

```bash
# .env.example
DEBUG=False
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=api.yourapp.com,localhost

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/tailor_db

# AWS S3
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_STORAGE_BUCKET_NAME=tailor-app-media
AWS_S3_REGION_NAME=ap-south-1

# Email
EMAIL_HOST=smtp.sendgrid.net
EMAIL_PORT=587
EMAIL_HOST_USER=apikey
EMAIL_HOST_PASSWORD=your-sendgrid-key

# SMS
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=+1234567890

# Push Notifications
FCM_SERVER_KEY=your-fcm-server-key

# Payment Gateways
RAZORPAY_KEY_ID=your-razorpay-key
RAZORPAY_KEY_SECRET=your-razorpay-secret
```

---

#### **2. Docker Setup**

```dockerfile
# Dockerfile
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Run migrations
RUN python manage.py migrate

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "config.wsgi:application"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=tailor_db
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
  
  web:
    build: .
    command: gunicorn config.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - .:/app
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      - db
      - redis
  
  celery:
    build: .
    command: celery -A config worker -l info
    volumes:
      - .:/app
    env_file:
      - .env
    depends_on:
      - db
      - redis
  
  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - web

volumes:
  postgres_data:
  static_volume:
  media_volume:
```

---

#### **3. Deployment Commands**

```bash
# Initial setup
docker-compose up -d --build

# Create superuser
docker-compose exec web python manage.py createsuperuser

# View logs
docker-compose logs -f web

# Database migrations
docker-compose exec web python manage.py makemigrations
docker-compose exec web python manage.py migrate

# Restart services
docker-compose restart web celery
```

---

### **📚 API Testing with Postman**

Create a Postman collection with:

1. **Environment Variables**
```json
{
  "base_url": "http://localhost:8000/api/v1",
  "access_token": "",
  "refresh_token": ""
}
```

2. **Pre-request Script** (Auto-refresh tokens)
```javascript
// Check if token is expired
const accessToken = pm.environment.get("access_token");
if (!accessToken || isTokenExpired(accessToken)) {
    const refreshToken = pm.environment.get("refresh_token");
    
    pm.sendRequest({
        url: pm.environment.get("base_url") + "/auth/refresh/",
        method: 'POST',
        header: {'Content-Type': 'application/json'},
        body: {
            mode: 'raw',
            raw: JSON.stringify({ refresh: refreshToken })
        }
    }, (err, res) => {
        const newAccessToken = res.json().access;
        pm.environment.set("access_token", newAccessToken);
    });
}
```

---

### **🎯 Next Steps**

1. **Week 1-2:** Setup Django project, models, basic CRUD
2. **Week 3-4:** Authentication, permissions, JWT
3. **Week 5-6:** Image upload, S3 integration, sync logic
4. **Week 7-8:** Payment gateway, notifications, analytics
5. **Week 9-10:** Testing, optimization, deployment

---

### **📞 Support & Resources**

- **Django Docs:** https://docs.djangoproject.com/
- **DRF Docs:** https://www.django-rest-framework.org/
- **JWT Auth:** https://django-rest-framework-simplejwt.readthedocs.io/
- **AWS S3:** https://django-storages.readthedocs.io/

---

**Status:** ✅ Complete API documentation ready for implementation  
**Estimated Development Time:** 8-10 weeks  
**Team Size:** 1-2 backend developers

