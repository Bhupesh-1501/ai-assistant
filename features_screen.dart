import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mypursu/view/genie/models/api_service.dart';
import 'package:mypursu/view/genie/pages/orderACake.dart';
import 'package:mypursu/view/genie/pages/sendAGift.dart';
import 'package:mypursu/view/genie/pages/shopForMe.dart';
import 'package:mypursu/view/genie/pages/travel_page.dart';
import 'package:mypursu/view/genie/widget/action_config.dart';
import 'package:mypursu/view/genie/widget/chat_screen.dart';
import 'package:mypursu/view/genie/widget/chirag_dotted_cricle.dart';
import 'package:mypursu/view/genie/widget/dooted.dart';
import 'package:mypursu/view/genie/widget/feature_autoscroll.dart';
import 'package:remit2any_auth/remit2any_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/check_error.dart';
import '../../model/get_user_model.dart';
import '../../utils/api_headers.dart';
import '../../utils/constant.dart';
import '../activities/your_activities.dart';
import '../concierge_package/add_money_nri.dart';
import '../mailbox/view/mailbox.dart';
import '../pay_request/bill_request_screen.dart';
import '../scan_and_pay/pay_to_upi.dart';
import '../withdraw/withdraw.dart';
import 'models/genie_Model.dart';


class Geniehome extends StatefulWidget {
  const Geniehome({super.key});

  @override
  State<Geniehome> createState() => _GeniehomeState();
}

class _GeniehomeState extends State<Geniehome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E4FA8),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2C6BD9),
                Color(0xFF173A7A),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GenieCard(),
              // GenieWelcomeCard(),
            ),
          ),
        ),
      ),
    );
  }
}


class GenieCard extends StatefulWidget {
  @override
  State<GenieCard> createState() => _GenieCardState();
}

class _GenieCardState extends State<GenieCard>
    with SingleTickerProviderStateMixin {
  late AudioPlayer player;
  int? loggedInUserId;
  bool showFirst = true;

  List<GenieButtonConfig> topButtons = [];
  List<GenieButtonConfig> leftButtons = [];
  List<GenieButtonConfig> rightButtons = [];
  bool isLoading = true;

  late AnimationController _controller;
  late ScrollController _topController;
  late ScrollController _bottomController;
  var id;
  String travelPurpose = "";
  String startDate = "";
  String endDate = "";
  bool isUsKycCompleted = true;
  bool isIndiaKycCompleted = true;

  String userNamed = "";
  String userMobiled = "";
  String phoneCode = "";
  String userEmail = "";
  String companyUser = "";
  String addressStr = "";

  /* @override
 void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // speed of rotation
    )..repeat();

    _topController = ScrollController();
    _bottomController = ScrollController();
    fetchGenieConfig();

    // player = AudioPlayer();
    //
    // player.setAudioContext(
    //   AudioContext(
    //     iOS: AudioContextIOS(
    //       category: AVAudioSessionCategory.playback,
    //       options: [
    //         AVAudioSessionOptions.mixWithOthers,
    //       ],
    //     ),
    //   ),
    // );

    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        showFirst = !showFirst;
      });
    });
  }*/
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _topController = ScrollController();
    _bottomController = ScrollController();

    _loadUserAndGenie(); // 👈 NEW

    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        showFirst = !showFirst;
      });
    });
  }

  Future<void> _loadUserAndGenie() async {
    await getUser(); // userName etc
    await fetchGenieConfig(); // Genie API
  }

  Future<void> fetchGenieConfig() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userIdDtl');

      if (userId == null) {
        debugPrint("❌ userId null");
        return;
      }

      final response = await GenieApiService.getGenieConfig(userId);

      if (response.statusCode != 200) {
        debugPrint("❌ API failed");
        setState(() => isLoading = false);
        return;
      }

      final decoded = jsonDecode(response.body);
      final appConfigList = decoded['rData']['appConfigList'];

      topButtons.clear();
      leftButtons.clear();
      rightButtons.clear();

      for (var category in appConfigList) {
        final cat = category['category'];
        final buttons = category['appConfigs'] as List;

        for (var btn in buttons) {
          final config = GenieButtonConfig.fromJson(btn);

          if (cat == "top") {
            topButtons.add(config);
          } else if (cat == "left") {
            leftButtons.add(config);
          } else if (cat == "right") {
            rightButtons.add(config);
          }
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("🔥 Genie crash => $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userId = prefs.getInt('userIdDtl');
    var userurl = '${Constants().apiUrl}/getUser';
    print("GetUser API Calling : $userurl");
    var body = jsonEncode({"userId": userId});
    var response = await http.post(Uri.parse(userurl),
        body: body, headers: await ApiHeaders.getAuthHeaders());
    debugPrint("response :: ${response.body}");
    if (response.statusCode == 200) {
      var mdata = json.decode(response.body);
      var errcheck = CheckError.fromJson(mdata);
      if (!errcheck.is_error!) {
        var uerd = GetUser.fromJson(mdata);
        var sharedPreferences = await SharedPreferences.getInstance();

        sharedPreferences.setString(
            "userName", uerd.rData!.users![0].fullName!);
        setState(() {
          userNamed = uerd.rData!.users![0].fullName!;
        });
      }
    } else if (response.statusCode == 401) {
      // Unauthorized
      print('Unauthorized. Redirecting to login...');
      ApiHeaders.handleReAuthentication(context);
    } else
      return null;
  }

  @override
  void dispose() {
    player.dispose();
    _controller.dispose();

    _topController.dispose();
    _bottomController.dispose();

    super.dispose();
  }

  // void playSound() async {
  //   print("Trying to play sound...");
  //   await player.play(AssetSource('resources/sounds/genie_sound.mp3'));
  //   // await player.stop();
  //   // print("Audio result: $result");
  // }

  String getIconLink(String? id) {
    if (id == null || id.isEmpty) return "";
    return "https://drive.google.com/uc?export=view&id=$id";
  }

  void handleGenieAction(GenieButtonConfig btn) {
    switch (btn.buttonKey) {
      case "pay_now":
        launchUrl(Uri.parse(btn.url));
        // Scan & Pay
        break;

      case "pay_to_upi":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PayToUpiPage(
              id.toString(),
              travelPurpose,
              startDate,
              endDate,
            ),
          ),
        );
        break;

      case "mailbox":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Mailbox(tabIndex: 1)),
        );
        break;

      case "remit2any":
        launchUrl(Uri.parse(btn.url));
        break;

      case "withdraw":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WithdrawPage()),
        );
        break;

      case "travel_bookings":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => travelPage()),
        );
        break;

      default:
        debugPrint("⚠️ No action mapped for ${btn.buttonKey}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF98BBDB),
            // color: Colors.red,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // playSound();
                        print("BBBBBBBplaySound");
                      },
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.transparent,
                        child: Image.asset(
                            "resources/images/genie/images/sound-volume-2.png"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFC9D8FF),
                        child: Icon(
                          Icons.close,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      "resources/images/genie/images/sparkles-sharp.png",
                      height: 19,
                      width: 19,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "I suggest you some Services you can \nclick...",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          fontFamily: 'Inter',
                          foreground: Paint()
                            ..shader = LinearGradient(
                              colors: [
                                Color(0xFF2D6FD3),
                                Color(0xFF495BDB),
                                Color(0xFF6622D6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(
                                Rect.fromLTWH(100.0, 0.0, 200.0, 70.0)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                  Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    primaryButton(
                      "Scan and Pay",
                      "resources/images/icon_scan&pay.png",
                    ),
                    outlinedButton("Mailbox",
                        "resources/images/genie/images/mail-minus.png",
                        onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Mailbox(
                            tabIndex: 1,
                            // lockerId: lockerId,
                            // offerName: Constants
                            //     .offerList![index]
                            //     .offerName,
                          ),
                        ),
                      );
                    }),
                    outlinedButton(
                      "Pay to UPI",
                      "resources/images/genie/images/money-send.png",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PayToUpiPage(
                              id.toString(),
                              travelPurpose,
                              startDate,
                              endDate,
                            ),
                          ),
                        );
                      },
                    ),
                    outlinedButton("Bill Payments",
                        "resources/images/genie/images/Bill Payment.png",
                        onTap: () async {
                      var value = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BillRequestScreen(),
                        ),
                      );
                    }),
                    outlinedButton("Buy Concierge Package",
                        "resources/images/genie/images/add_money_img.png",
                        onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddMoneyNRI(
                                  Constants.kycStatus,
                                  id,
                                  travelPurpose,
                                  startDate,
                                  endDate)));
                    }),
                    primaryOrangeButton("Mypursu Remit2any",
                        "resources/images/genie/images/icon_remit2Any.png"),
                  ],
                ),

                const SizedBox(height: 16),
           
                 Column(
                  children: [
                    AutoServiceScroller(
                      scrollRight: true,
                      items: [
                        ServiceItem(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GenieChatScreen(
                                  config: GenieActionConfig(
                                    buttonText: "Shop for me",
                                    loadingText: "Going to shopping page...",
                                    destinationPage: ShopForMeScreen(),
                                  ),
                                ),
                              ),
                            );
                          },
                          title: "Shop For Me",
                          iconPath:
                              "resources/images/genie/images/shopping-cart.png",
                        ),
                        ServiceItem(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => TransactionActivity(
                                            username: userNamed,
                                          )));
                            },
                            title: "History",
                            iconPath:
                                "resources/images/genie/images/history-scroll.png"),
                        ServiceItem(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    // builder: (context) => SentAGiftScreen(),
                                    builder: (_) => GenieChatScreen(
                                      config: GenieActionConfig(
                                        buttonText: "Send a Gift",
                                        loadingText: "Going to Send a Gift...",
                                        destinationPage: SentAGiftScreen(),
                                      ),
                                    ),
                                  ));
                            },
                            title: "Chatting With Genie",
                            iconPath:
                                "resources/images/genie/images/send-gift.png"),
                        ServiceItem(
                            onTap: () {},
                            title: "Pay to static QR",
                            iconPath:
                                "resources/images/genie/images/qr-code.png"),
                        ServiceItem(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const WithdrawPage()));
                            },
                            title: "Withdraw",
                            iconPath:
                                "resources/images/genie/images/wallet-money.png"),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AutoServiceScroller(
                      scrollRight: false,
                      items: [
                        ServiceItem(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GenieChatScreen(
                                    config: GenieActionConfig(
                                      buttonText: "Travel Bookings",
                                      loadingText:
                                          "Genie is Waiting for You at Location...",
                                      destinationPage: travelPage(),

                                      // TravelBooking(),
                                    ),
                                  ),
                                  // builder: (context) => const TravelBooking(),
                                ),
                              );
                            },
                            title: "Chatting With Genie",
                            iconPath:
                                "resources/images/genie/images/flight_img.png"),
                        ServiceItem(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GenieChatScreen(
                                      config: GenieActionConfig(
                                        buttonText: "Order a Cake",
                                        loadingText: "Going to Order a Cake...",
                                        destinationPage: OrderCakeScreen(),
                                      ),
                                    ),

                                    // builder: (context) => OrderCakeScreen(),
                                  ));
                            },
                            title: "Chatting With Genie",
                            iconPath: "resources/images/genie/images/cake.png"),
                        ServiceItem(
                            onTap: () {},
                            title: "Pack N Ship",
                            iconPath:
                                "resources/images/genie/images/pns_img.png"),
                        ServiceItem(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => TransactionActivity(
                                            username: userNamed,
                                          )));
                            },
                            title: "Task History & Receipts",
                            iconPath:
                                "resources/images/genie/images/recipt.png"),
                      ],
                    ),
                  ],
                ),
               
         

                const SizedBox(height: 20),
                AnimatedDots(),
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF659AEA),
                      Color(0xFFA9B0E1),
                      Color(0xFF8E6FC1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: Text(
                    "Chat With Genie",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'inter',
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: TextField(
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: "Ask anything...",
                            hintStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFEAF3FF),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Image.asset(
                                "resources/images/genie/images/mic-outline.png",
                                width: 20,
                                height: 20,
                              ),
                            ),
                            suffixIconConstraints: const BoxConstraints(
                                minHeight: 20, minWidth: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const SizedBox(
                      height: 60,
                      width: 60,
                      child: RotatingCircleAvatar(),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        Positioned(
          top: -40,
          left: -15,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(pi),
            child: Image.asset(
              "resources/images/genie/gifs/0930faebf83585c6c0b651cadb1a11d903bd518d.gif",
              height: 90,
            ),
          ),
        ),
      ],
    );
  }

  Widget genieButton(GenieButtonConfig btn, {bool isPrimary = false}) {
    return ElevatedButton(
      onPressed: () => handleGenieAction(btn),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: const StadiumBorder(),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFFE6652E), Color(0xFFFB9164)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: isPrimary ? null : Border.all(color: const Color(0xFF53A4E7)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              /*Image.network(
                "https://do.api.qa.mypursu.com/api/file/download/${btn.icon}",
                height: 22,
                width: 22,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
              ),*/
              CachedNetworkImage(
                imageUrl: getIconLink(btn.icon),
                height: 22,
                width: 22,
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, size: 22),
              ),
              const SizedBox(width: 8),
              Text(
                btn.buttonName,
                style: TextStyle(
                  color: isPrimary ? Colors.white : Colors.black,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget primaryButton(String text, String iconPath) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // important for gradient
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFE57A4FF), // #E6652E
                Color(0xFFF1D6CB4), // #FB9164
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(25),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  iconPath,
                  height: 22,
                  width: 22,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget outlinedButton(
    String text,
    String iconPath, {
    required VoidCallback onTap,
  }) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          shape: const StadiumBorder(),
          side: const BorderSide(color: Color(0xFF53A4E7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              height: 22,
              width: 22,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget primaryOrangeButton(String text, String iconPath) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // important for gradient
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFE6652E), // #E6652E
                Color(0xFFFB9164), // #FB9164
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(25),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  iconPath,
                  height: 22,
                  width: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
