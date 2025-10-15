import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
// Widgets import is required for WidgetState/WidgetStateProperty (MaterialStateProperty deprecated)
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:economicskills/app/widgets/drawer_nav.widget.dart';
import 'package:economicskills/app/widgets/top_nav.widget.dart';
// **New import for YouTube player:**
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:economicskills/app/widgets/google_sheet_embed.widget.dart';
/// A page showing how to estimate a quadratic demand curve.
/// This widget uses a `CustomScrollView` to allow the top navigation bar to stick
/// at the top while scrolling through the page contents. Horizontal padding is
/// always applied to ensure the content doesn't hug the left and right edges
/// of the device, regardless of screen size.
class ElasticityPage extends StatefulWidget {
  const ElasticityPage({super.key});
  @override
  State<ElasticityPage> createState() => _ElasticityPageState();
}
class _ElasticityPageState extends State<ElasticityPage> {
  late final YoutubePlayerController _ytController;
  bool _isSourcesExpanded = false;
  @override
  void initState() {
    super.initState();
// Initialize the YouTube player controller with the video ID
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: 'U_ctU4E-BuI', // YouTube video ID for https://youtu.be/U_ctU4E-Bu
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true, // Only show videos from the same channel at end
        showVideoAnnotations: false, // Hide pop-up annotations/end cards
      ),
    );
  }
  @override
  void dispose() {
    _ytController.pauseVideo();
    _ytController.close(); // not .dispose()
    super.dispose();
  }
// Helper method to launch URLs
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: kToolbarHeight, // Assuming TopNav uses standard AppBar height
            collapsedHeight: kToolbarHeight,
            toolbarHeight: kToolbarHeight,
            flexibleSpace: TopNav(),
            automaticallyImplyLeading: false, // Let TopNav handle its own leading icon (e.g., drawer)
            titleSpacing: 0, // Remove default title spacing if TopNav fills the bar
            title: const SizedBox.shrink(), // No default title, TopNav is the content
// backgroundColor: Colors.transparent, // Optional: if TopNav has its own background
// elevation: 0, // Optional: if TopNav handles its own shadow
          ),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
// Always apply horizontal padding; previously this was conditional on screen width.
                final double horizontalPadding = 16.0;
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1140),
// SingleChildScrollView is removed here as CustomScrollView handles scrolling
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 30.0),
// Title
                          Text(
                            'Constant price elasticity of demand', //Estimating a quadratic demand curve
                            textAlign: TextAlign.center,
                            style: (Theme.of(context).textTheme.displaySmall ??
                                const TextStyle(fontSize: 36.0, fontWeight: FontWeight.w400))
                                .copyWith(
                              fontFamily: 'ContrailOne',
                              color: Theme.of(context).textTheme.bodyLarge?.color ??
                                  (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade300 : Colors.black87),),
                          ),
                          const SizedBox(height: 40.0), // spacing between title and video
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: RichText(
                              textAlign: TextAlign.start,
                              text: TextSpan(
                                style: (Theme.of(context).textTheme.bodyLarge ??
                                    const TextStyle(fontSize: 16.0))
                                    .copyWith(
                                  height: 1.5,
                                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                                      (Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade300
                                          : Colors.black87),
                                ),
                                children: const [
                                  TextSpan(
                                    text:
                                    'In this lesson we are going to learn how to model demand assuming a constant price elasticity.', // calculate / within a given price range
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40.0), // bottom spacing
// **YouTube inline player widget:**
                          YoutubePlayer(
                            controller: _ytController,
                            aspectRatio: 16 / 9, // maintains 16:9 aspect ratio for the player
                          ),
                          const SizedBox(height: 40.0), // spacing between video and text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: RichText(
                              textAlign: TextAlign.start,
                              text: TextSpan(
                                style: (Theme.of(context).textTheme.bodyLarge ??
                                    const TextStyle(fontSize: 16.0))
                                    .copyWith(
                                  height: 1.5,
                                  color: Theme.of(context).textTheme.bodyLarge?.color
                                      ?? (Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade300 : Colors.black87),
                                ),
                                children: const [
                                  TextSpan(text: 'Exercise 1\n\n', style: TextStyle(fontSize: 20.0, fontFamily: 'ContrailOne')),
                                  TextSpan(text: 'Insert a line chart showing the relationship between price and demand.'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40.0), // bottom spacing
// Embedded Google Sheet for interactive practice.
                          GoogleSheetEmbed(
                            sheetUrl:
                            'https://docs.google.com/spreadsheets/d/1pGfJ0-RKy2vR3lltaUzRgHwwBb1R4yJN1EbZehTWbnQ/edit?usp=sharing&widget=true',
                            height: 580.0,
                          ),
                          const SizedBox(height: 40.0), // spacing between video and text

                          // Submit Answer button aligned to the right
                          Align(
                            alignment: Alignment.centerRight,
                            child: Tooltip(
                              message: 'This feature is in development.',
                              child: TextButton(
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                                        (Set<WidgetState> states) {
                                      return Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade200;
                                    },
                                  ),
                                ),
                                onPressed: () {
// Show a SnackBar to display the in-development message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('This feature is in development.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Submit Answer',
                                  style: TextStyle(
                                    fontSize: 19.0,
                                    fontFamily: 'ContrailOne',
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40.0),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
// Clickable Sources header with expand/collapse icon
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isSourcesExpanded = !_isSourcesExpanded;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        'Sources:', 
                                        style: TextStyle(
                                          fontSize: 20.0,
                                          fontFamily: 'ContrailOne',
                                          color: Theme.of(context).textTheme.bodyLarge?.color ??
                                              (Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey.shade300 : Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                      AnimatedRotation(
                                        turns: _isSourcesExpanded ? 0.25 : 0.0,
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          Icons.keyboard_arrow_right,
                                          color: Theme.of(context).textTheme.bodyLarge?.color ??
                                              (Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey.shade300 : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16.0),
// Animated expandable sources content
                                AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 300),
                                  crossFadeState: _isSourcesExpanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: RichText(
                                    textAlign: TextAlign.start,
                                    text: TextSpan(
                                      style: (Theme.of(context).textTheme.bodyLarge ??
                                          const TextStyle(fontSize: 16.0))
                                          .copyWith(
                                        height: 1.5,
                                        color: Theme.of(context).textTheme.bodyLarge?.color
                                            ?? (Theme.of(context).brightness == Brightness.dark
                                                ? Colors.grey.shade300 : Colors.black87),
                                      ),
                                      children: [
                                        const TextSpan(text: 'Hayes, A. (2025, June 13). '),
                                        const TextSpan(
                                          text: 'Price elasticity of demand: Meaning, types, and factors that impact it',
                                          style: TextStyle(fontStyle: FontStyle.italic),
                                        ),
                                        const TextSpan(text: '. Investopedia. '),
                                        TextSpan(
                                          text: 'https://www.investopedia.com/terms/p/priceelasticity.asp',
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.lightBlue.shade900, //cyan.shade700,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _launchUrl('https://www.investopedia.com/terms/p/priceelasticity.asp'),
                                        ),
                                        const TextSpan(text: '\n\n'),
                                        const TextSpan(text: 'Marcott, C. (2015, February). '),
                                        const TextSpan(
                                          text: 'Constant price elasticity of demand',
                                          style: TextStyle(fontStyle: FontStyle.italic),
                                        ),
                                        const TextSpan(text: '. Wolfram Demonstrations Project. '),
                                        TextSpan(
                                          text: 'https://demonstrations.wolfram.com/ConstantPriceElasticityOfDemand/',
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.lightBlue.shade900,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _launchUrl('https://demonstrations.wolfram.com/ConstantPriceElasticityOfDemand/'),
                                        ),
                                        const TextSpan(text: '\n\n'),
                                        const TextSpan(text: 'Winston, W. L. (2014). '),
                                        const TextSpan(
                                          text: 'Marketing analytics: Data-driven techniques with Microsoft Excel',
                                          style: TextStyle(fontStyle: FontStyle.italic),
                                        ),
                                        const TextSpan(text: ' (pp. 85-106). Wiley. '),
                                        TextSpan(
                                          text: 'https://www.wiley.com/en-it/Marketing+Analytics%3A+Data-Driven+Techniques+with+Microsoft+Excel-p-9781118373439',
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.lightBlue.shade900,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _launchUrl('https://www.wiley.com/en-it/Marketing+Analytics%3A+Data-Driven+Techniques+with+Microsoft+Excel-p-9781118373439'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40.0), // spacing after the embedded sheet

                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width > ScreenSizes.md ? null : DrawerNav(),
    );
  }
}
