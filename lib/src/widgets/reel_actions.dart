import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/reel_controller.dart';
import '../models/reel_config.dart';
import '../models/reel_model.dart';
import '../utils/reel_utils.dart';

/// Widget that displays action buttons (like, comment, share, etc.) on the right side
class ReelActions extends StatefulWidget {
  final ReelModel reel;
  final ReelConfig config;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onFollow;
  final VoidCallback? onBlock;

  const ReelActions({
    super.key,
    required this.reel,
    required this.config,
    this.onLike,
    this.onShare,
    this.onComment,
    this.onFollow,
    this.onBlock,
  });

  @override
  State<ReelActions> createState() => _ReelActionsState();
}

class _ReelActionsState extends State<ReelActions>
    with TickerProviderStateMixin {
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReelController>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button
        _buildLikeButton(controller),
        const SizedBox(height: 16),
        // Comment button
        _buildCommentButton(controller),
        const SizedBox(height: 16),
        // Share button
        _buildShareButton(controller),
        const SizedBox(height: 16),
        // Bookmark button (only show if not in more menu)
        if (widget.config.showBookmarkButton &&
            !widget.config.bookmarkInMoreMenu)
          _buildActionButton(
            icon: widget.reel.isBookmarked
                ? Icons.bookmark
                : Icons.bookmark_border,
            iconColor: widget.reel.isBookmarked
                ? widget.config.accentColor
                : widget.config.textColor,
            onTap: () => _handleBookmark(controller),
          ),
        if (widget.config.showBookmarkButton &&
            !widget.config.bookmarkInMoreMenu)
          const SizedBox(height: 16),
        // Download button (only show if not in more menu)
        if (widget.config.showDownloadButton &&
            !widget.config.downloadInMoreMenu)
          _buildActionButton(
            icon: Icons.download,
            iconColor: widget.config.textColor,
            onTap: () => _handleDownload(controller),
          ),
        if (widget.config.showDownloadButton &&
            !widget.config.downloadInMoreMenu)
          const SizedBox(height: 16),
        // More options button
        if (widget.config.showMoreButton) _buildMoreButton(controller),
        if (widget.config.showMoreButton) const SizedBox(height: 16),
        // Creator avatar (spinning music note style)
        if (widget.reel.musicTitle != null) _buildMusicAvatar(),
      ],
    );
  }

  // ── Like ──────────────────────────────────────────────────────────────────

  Widget _buildLikeButton(ReelController controller) {
    if (widget.config.likeButtonBuilder != null) {
      return widget.config.likeButtonBuilder!(
        widget.reel,
        widget.reel.isLiked,
        () => _handleLike(controller),
      );
    }
    return _DefaultLikeButton(
      reel: widget.reel,
      config: widget.config,
      onTap: () => _handleLike(controller),
    );
  }

  // ── Comment ───────────────────────────────────────────────────────────────

  Widget _buildCommentButton(ReelController controller) {
    if (widget.config.commentButtonBuilder != null) {
      return widget.config.commentButtonBuilder!(
        widget.reel,
        () => _handleComment(controller),
      );
    }
    return _buildActionButton(
      icon: Icons.chat_bubble_outline,
      iconColor: widget.config.textColor,
      count: widget.reel.commentsCount,
      onTap: () => _handleComment(controller),
    );
  }

  // ── Share ─────────────────────────────────────────────────────────────────

  Widget _buildShareButton(ReelController controller) {
    if (widget.config.shareButtonBuilder != null) {
      return widget.config.shareButtonBuilder!(
        widget.reel,
        () => _handleShare(controller),
      );
    }
    return _buildActionButton(
      icon: Icons.send_outlined,
      iconColor: widget.config.textColor,
      count: widget.reel.sharesCount,
      onTap: () => _handleShare(controller),
    );
  }

  // ── More ──────────────────────────────────────────────────────────────────

  Widget _buildMoreButton(ReelController controller) {
    if (widget.config.moreButtonBuilder != null) {
      return widget.config.moreButtonBuilder!(
        widget.reel,
        () => _showMoreOptions(context, controller),
      );
    }
    return _buildActionButton(
      icon: Icons.more_vert,
      iconColor: widget.config.textColor,
      onTap: () => _showMoreOptions(context, controller),
    );
  }

  // ── Generic action button ─────────────────────────────────────────────────

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    int? count,
    required VoidCallback onTap,
    Animation<double>? animation,
  }) {
    Widget iconWidget = Icon(icon, color: iconColor, size: 28);

    if (animation != null && !_isDisposed) {
      iconWidget = Transform.scale(scale: animation.value, child: iconWidget);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            iconWidget,
            if (count != null && count > 0) ...[
              const SizedBox(height: 0),
              Text(
                ReelUtils.formatCount(count),
                style: TextStyle(
                  color: widget.config.textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Music avatar ──────────────────────────────────────────────────────────

  Widget _buildMusicAvatar() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _pulseAnimationController.value * 2 * 3.14159,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    widget.config.accentColor,
                    widget.config.accentColor.withAlpha(128),
                  ],
                ),
                border: Border.all(color: widget.config.textColor, width: 2),
              ),
              child: Icon(
                Icons.music_note,
                color: widget.config.textColor,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _handleLike(ReelController controller) {
    controller.toggleLike(widget.reel);
    if (!widget.reel.isLiked && mounted) _showFloatingHeart();
    if (widget.onLike != null) widget.onLike!();
  }

  void _handleComment(ReelController controller) {
    if (widget.config.onCommentTap != null) {
      widget.config.onCommentTap!(widget.reel);
    } else {
      _showCommentsBottomSheet(context, controller);
    }
    if (widget.onComment != null) widget.onComment!();
  }

  void _handleShare(ReelController controller) {
    controller.incrementShare(widget.reel);
    if (widget.config.onShareTap != null) {
      widget.config.onShareTap!(widget.reel);
    } else {
      final url = widget.reel.videoSource?.url ?? widget.reel.videoUrl;
      debugPrint('Sharing reel: $url');
    }
    if (widget.onShare != null) widget.onShare!();
  }

  void _handleBookmark(ReelController controller) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.reel.isBookmarked
              ? 'Removed from bookmarks'
              : 'Added to bookmarks',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: widget.config.accentColor,
      ),
    );
  }

  void _handleDownload(ReelController controller) {
    if (widget.config.onDownloadTap != null) {
      widget.config.onDownloadTap!(widget.reel);
    } else {
      controller.downloadReel(widget.reel);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Download started...'),
          duration: const Duration(seconds: 2),
          backgroundColor: widget.config.accentColor,
        ),
      );
    }
  }

  void _showFloatingHeart() {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;
    late AnimationController animationController;

    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Positioned(
            left: position.dx + 20,
            top: position.dy - (50 * animation.value),
            child: Opacity(
              opacity: 1.0 - animation.value,
              child: Transform.scale(
                scale: 0.5 + (0.5 * animation.value),
                child: const Icon(Icons.favorite, color: Colors.red, size: 30),
              ),
            ),
          );
        },
      ),
    );

    overlay.insert(overlayEntry);
    animationController.forward().then((_) {
      overlayEntry.remove();
      animationController.dispose();
    });
  }

  void _showCommentsBottomSheet(
      BuildContext context, ReelController controller) {
    final TextEditingController commentController = TextEditingController();
    final FocusNode commentFocusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text('Comments',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        Text(
                          ReelUtils.formatCount(widget.reel.commentsCount),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: widget.config.accentColor,
                                child: Text(
                                  'U${index + 1}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'user${index + 1}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('2h',
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This is a sample comment #${index + 1}. Great content!',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Reply',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.favorite_border,
                                        size: 18, color: Colors.grey[600]),
                                    onPressed: () {},
                                  ),
                                  Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border:
                          Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: widget.config.accentColor,
                          child: const Icon(Icons.person,
                              size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            focusNode: commentFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (text) {
                              if (text.trim().isNotEmpty) {
                                commentController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Comment posted!'),
                                    backgroundColor: widget.config.accentColor,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            final text = commentController.text.trim();
                            if (text.isNotEmpty) {
                              commentController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Comment posted!'),
                                  backgroundColor: widget.config.accentColor,
                                ),
                              );
                            }
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: widget.config.accentColor,
                            child: const Icon(Icons.send,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, ReelController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.config.showBookmarkButton &&
                widget.config.bookmarkInMoreMenu)
              ListTile(
                leading: Icon(widget.reel.isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border),
                title: Text(widget.reel.isBookmarked
                    ? 'Remove bookmark'
                    : 'Add bookmark'),
                onTap: () {
                  Navigator.pop(context);
                  _handleBookmark(controller);
                },
              ),
            if (widget.config.showDownloadButton &&
                widget.config.downloadInMoreMenu)
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download'),
                onTap: () {
                  Navigator.pop(context);
                  _handleDownload(controller);
                },
              ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                _handleReport(controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block user'),
              onTap: () {
                Navigator.pop(context);
                _handleBlock(controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy link'),
              onTap: () {
                Navigator.pop(context);
                _handleCopyLink(controller);
              },
            ),
            ...widget.config.customActions.map((action) => ListTile(
                  leading: Icon(action.icon),
                  title: Text(action.title),
                  onTap: () {
                    Navigator.pop(context);
                    action.onTap(widget.reel);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _handleReport(ReelController controller) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Content reported'),
        backgroundColor: widget.config.accentColor,
      ),
    );
  }

  void _handleBlock(ReelController controller) {
    if (widget.reel.user?.id == null) return;
    controller.blockUser(widget.reel.user!.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('User blocked'),
        backgroundColor: widget.config.accentColor,
      ),
    );
    if (widget.onBlock != null) widget.onBlock!();
  }

  void _handleCopyLink(ReelController controller) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link copied to clipboard'),
        backgroundColor: widget.config.accentColor,
      ),
    );
  }
}

// ── Default like button ────────────────────────────────────────────────────

/// A self-contained animated like button using only Flutter built-in icons.
/// Consumers can replace this entirely via [ReelConfig.likeButtonBuilder].
class _DefaultLikeButton extends StatefulWidget {
  final ReelModel reel;
  final ReelConfig config;
  final VoidCallback onTap;

  const _DefaultLikeButton({
    required this.reel,
    required this.config,
    required this.onTap,
  });

  @override
  State<_DefaultLikeButton> createState() => _DefaultLikeButtonState();
}

class _DefaultLikeButtonState extends State<_DefaultLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.reel.isLiked;
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : widget.config.textColor,
                size: 32,
              ),
            ),
            if (widget.reel.likesCount > 0) ...[
              const SizedBox(height: 2),
              Text(
                ReelUtils.formatCount(widget.reel.likesCount),
                style: TextStyle(
                  color: widget.config.textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
