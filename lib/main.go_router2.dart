import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web_url_strategy/web_url_strategy.dart';

/*
* <go_routerバージョン：次に兄弟方式（GoRouteのpathに「/」不要）>
*   => TODO 兄弟方式の場合、親子関係は予め決まっておらず画面遷移時にpush/popで命令的に決める
*     （Config時（appRouter）に親子関係を一元管理させない
*       => 従来のNavigator.push/popと考えで使える
*       （従来のNavigator.push/pop方式で画面のURLだけ欲しい場合：Wonderousもこのやり方に見える）
*       => どっちの方がいいのかは正直好みだと思う
*
*
*  ＜進め方＞
*   ０．appRouter（画面遷移の家系図）を親子方式から兄弟方式に変更
*     => 「"top-level path must start with \"/\": GoRoute(name: null, path: normal)"
*         エラーを出して１に進んでからgoメソッドのままだとどうなるのか実演しよう
*       （皆兄弟で子供がいないので、goだとpushではなくpushReplacementされてしまって前の画面に戻れない。AppBarに戻る矢印も出ない！）
*
*   １．ScreenPathsのパスに「/」必要
*     （ないと「"top-level path must start with \"/\": GoRoute(name: null, path: normal)"）」
*     => その代わりにgoメソッドはそのまま渡せる
*   ２．goメソッドをpush/popに変更
*
* */

void main() {
  WebUrlStrategy().setPathUrlStrategy();
  runApp(MyApp());
}

class ScreenPaths {

  static String home = "/";
  //TODO[go_router.１]親子方式の場合はGoRouteのpathに「/」必要
  //ルートのパスには「/」が必要だが、childRouteには「/」をつけてはいけない
  //"top-level path must start with \"/\": GoRoute(name: null, path: normal)"になる
  static String normal = "/normal";
  static String willPop = "/will_pop";
  static String confirmDialog = "/confirm_dialog";
  // static String normal = "normal";
  // static String willPop = "will_pop";
  // static String confirmDialog = "confirm_dialog";
}

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: ScreenPaths.home,
      builder: (context, state) => HomeScreen(),
    ),
    //TODO[０]appRouter（画面遷移の家系図）を親子方式から兄弟方式に変更
    GoRoute(
      path: ScreenPaths.normal,
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: NormalScreen(),
          transitionDuration: Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: ScreenPaths.confirmDialog,
      //builder(戻り値Widget）ではなくpageBuilder（戻り値pageBuilder）にする必要あり
      pageBuilder: (context, state) => DialogPage(
        builder: (_) => ConfirmDialog(),
      ),
    ),
    GoRoute(
      path: ScreenPaths.willPop,
      builder: (context, state) {
        final param = (state.extra != null) ? state.extra as String : "値なし";
        return WillPopScreen(param: param);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = [
    NormalPage(),
    ShowDialogPage(),
    WillPopPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (selectedIndex) {
          setState(() {
            _currentIndex = selectedIndex;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.ad_units), label: "Normal"),
          BottomNavigationBarItem(icon: Icon(Icons.zoom_in), label: "Dialog"),
          BottomNavigationBarItem(icon: Icon(Icons.nat), label: "WillPop"),
        ],
      ),
    );
  }
}

//------- １．Normal -------

class NormalPage extends StatelessWidget {
  const NormalPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueAccent,
      child: Center(
        child: ElevatedButton(
          onPressed: () => _openNormalScreen(context),
          child: Text("NormalScreenを開く"),
        ),
      ),
    );
  }

  _openNormalScreen(BuildContext context) {
    //TODO [go_router２]goメソッドをpush/popに変更（goのままだとどうなるか実演）
    //  => pathに「/」入れてるのでgoメソッドの引数に「/」加える必要なし
    context.push(ScreenPaths.normal);
    //context.go("/${ScreenPaths.normal}");

  }
}

class NormalScreen extends StatelessWidget {
  const NormalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Text("NormalScreen"),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _closeNormalScreen(context),
          child: Text("もどる"),
        ),
      ),
    );
  }

  _closeNormalScreen(BuildContext context) {
    //TODO [go_router２]goメソッドをpush/popに変更（goのままだとどうなるか実演）
    //  => pathに「/」入れてるのでgoメソッドの引数に「/」加える必要なし
    context.pop();
    //context.go("/${ScreenPaths.home}");

  }
}

//------- ２．Dialog -------
class ShowDialogPage extends StatelessWidget {
  const ShowDialogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          //TODO [go_router２]goメソッドをpush/popに変更（goのままだとどうなるか実演）
          //  => pathに「/」入れてるのでgoメソッドの引数に「/」加える必要なし
          onPressed: () => context.push(ScreenPaths.confirmDialog),
          //onPressed: () => context.go("/${ScreenPaths.confirmDialog}"),
          //onPressed: () => _openDialog(context),
          child: Text("Dialogを開く"),
        ),
      ),
    );
  }

  // _openDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text("ダイアログ"),
  //       actions: [
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.redAccent,
  //           ),
  //           //onPressed: () => Navigator.pop(context),
  //           onPressed: () => context.pop(context),
  //           child: Text("とじる"),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("ダイアログ"),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          //TODO [go_router２]goメソッドをpush/popに変更（ここはpopのまま）
          onPressed: () => context.pop(),
          //onPressed: () => Navigator.pop(context),
          child: Text("とじる"),
        ),
      ],
    );
  }
}

//------- ３．WillPop -------
class WillPopPage extends StatelessWidget {
  const WillPopPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          onPressed: () => _openWillPopScreen(context),
          child: Text("WillPopScreenを開く"),
        ),
      ),
    );
  }

  _openWillPopScreen(BuildContext context) {
    //TODO [go_router２]goメソッドをpush/popに変更
    //  => pathに「/」入れてるのでgoメソッドの引数に「/」加える必要なし
    context.push(ScreenPaths.willPop, extra: "渡される値");
    //context.go("/${ScreenPaths.willPop}", extra: "渡される値");
    }
}

class WillPopScreen extends StatelessWidget {
  final String param;

  const WillPopScreen({Key? key, required this.param}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _confirmCloseScreen(context),
      child: Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(
          title: Text("WillPopScreen"),
          centerTitle: true,
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Text(
            param,
            style: TextStyle(color: Colors.white, fontSize: 30.0),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmCloseScreen(BuildContext context) async {
    final isConfirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text("画面を閉じていいですか？"),
        actions: [
          TextButton(
            onPressed: () {
              //TODO [go_router２]goメソッドをpush/popに変更（ここはpopのまま）
              context.pop(true);
            },
            child: Text("閉じる"),
          ),
          TextButton(
            onPressed: () {
              //TODO [go_router２]goメソッドをpush/popに変更（ここはpopのまま）
              context.pop(false);
            },
            child: Text("キャンセル"),
          ),
        ],
      ),
    );
    return isConfirmed;
  }
}

//https://croxx5f.hashnode.dev/adding-modal-routes-to-your-gorouter#heading-tldr-the-solution
/// A dialog page with Material entrance and exit animations, modal barrier color,
/// and modal barrier behavior (dialog is dismissible with a tap on the barrier).
class DialogPage<T> extends Page<T> {
  final Offset? anchorPoint;
  final Color? barrierColor;
  final bool barrierDismissible;
  final String? barrierLabel;
  final bool useSafeArea;
  final CapturedThemes? themes;
  final WidgetBuilder builder;

  const DialogPage({
    required this.builder,
    this.anchorPoint,
    this.barrierColor = Colors.black54,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.useSafeArea = true,
    this.themes,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) => DialogRoute<T>(
      context: context,
      settings: this,
      builder: builder,
      anchorPoint: anchorPoint,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      themes: themes);
}
