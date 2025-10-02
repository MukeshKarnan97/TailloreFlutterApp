import 'package:flutter/material.dart';
import 'package:tailer_app/widgets/profile_dropdown.dart';
import 'package:tailer_app/data/services/user_service.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? titleColor;
  final double? elevation;

  const CustomHeader({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.onBackPressed,
    this.backgroundColor,
    this.titleColor,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      elevation: elevation ?? 2.0,
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      automaticallyImplyLeading: showBackButton,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomHeaderWithProfile extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? userImageUrl;
  final VoidCallback? onProfileTap;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const CustomHeaderWithProfile({
    Key? key,
    required this.title,
    this.userImageUrl,
    this.onProfileTap,
    this.actions,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      elevation: 2.0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: onProfileTap,
        child: Container(
          margin: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: userImageUrl != null && userImageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      userImageUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 20,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.grey,
                    size: 20,
                  ),
          ),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class DashboardHeader extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onNotificationTap;
  final Color? backgroundColor;
  final Color? titleColor;
  final String? appIconPath;
  final int notificationCount;

  const DashboardHeader({
    Key? key,
    required this.title,
    this.onBackPressed,
    this.onNotificationTap,
    this.backgroundColor,
    this.titleColor,
    this.appIconPath,
    this.notificationCount = 0,
  }) : super(key: key);

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DashboardHeaderState extends State<DashboardHeader> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _userService.initialize(); // Initialize user service
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: widget.backgroundColor ?? Theme.of(context).primaryColor,
      elevation: 3.0,
      shadowColor: Colors.black26,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Row(
          children: [
            // Back Button
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
              onPressed: widget.onBackPressed ?? () => Navigator.of(context).pop(),
              splashRadius: 24,
              tooltip: 'Back',
            ),
            // App Icon (right next to back button)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 2, right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.appIconPath != null
                    ? Image.asset(
                        widget.appIconPath!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF00695C),
                                  const Color(0xFF004D40),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.content_cut_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF00695C),
                              const Color(0xFF004D40),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.content_cut_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      leadingWidth: 110, // Increased width for better spacing
      title: Text(
        widget.title,
        style: TextStyle(
          color: widget.titleColor ?? Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      centerTitle: false, // Align title to the left for better visual flow
      actions: [
        // Profile Dropdown with Enhanced Features
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: ProfileDropdown(
            notificationCount: widget.notificationCount,
            userName: _userService.getUserDisplayName(),
            userEmail: _userService.getUserEmail(),
            userAvatarUrl: _userService.getUserProfilePicture(),
            onNotificationsTap: widget.onNotificationTap,
          ),
        ),
      ],
    );
  }
}