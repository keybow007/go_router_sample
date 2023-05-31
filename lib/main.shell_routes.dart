import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web_url_strategy/web_url_strategy.dart';

/*
* <go_routerバージョン３：親子方式（GoRouteのpathに「/」不要）をベースにShellRoutes>
*   => バージョン1（main.go_router1.dart）をコピー
* 複数のRouteを使いたい場合ShellRouteってやつを使うらしい（Nested Navigation）
* https://pub.dev/documentation/go_router/latest/topics/Configuration-topic.html#nested-navigation
* （例：BtmNaviでbodyの部分だけアプリ全体のNavigatorとは別のNavigatorを使いたい場合（）
* https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html
*   ・BtMNavi部分を残したまま子Pageから別の画面を開く
*   ・各PageにもURLを付与する
*   これもAndreaの良記事
*   https://codewithandrea.com/articles/flutter-bottom-navigation-bar-nested-routes-gorouter-beamer/
*   公式のサンプル
*   https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/shell_route.dart
*
*  ＜進め方＞
*   １．ScreenPathsのパス変更
*     ・HomeScreenのPage群にもパスを付与
*   ２．Page群・Screen群の名称変更
*          BtmNavi
*     ---- normal(NormalPage => NormalMasterScreen) -- detail (NormalScreen => NormalDetailScreen)
*       -- dialog(ShowDialogPage => ShowDialogMasterScreen) -- confirm_dialog(ConfirmDialog:変更なし）
*       -- willPop(WillPopPage => WillPopMasterScreen) -- detail(WillPopScreen => WillPopDetailScreen)
*
*   ３．HomeScreenのPage群もappRouterに加える
*      => HomeScreenの部分は削除
*   ４．NavigationのGlobalKeyを設定して３で作成したGoRoute群をShellRouteでくるむ（ScaffoldWithNavBarはこのあとで）
*   ５．HomeScreenをScaffoldWithNavBarの内容に変更（ShellRoute#builderのchildを渡せるように）
*       => 一度この段階でビルドしてWillPopScreenが画面全体にならないことを実演
*   ６．goメソッドの行き先（引数）変更 => childRouteに行く際のgoメソッドはルートからのフルパスを指定する必要があるので引数変更
*   ７．画面全体に表示させるRouteに”parentNavigatorKey”を設定（WillPopDetailScreen）
*     ・Normal・ShowDialogは子Navigatorに（BtmNavi残してbody部分だけ）、WillPopScopeは親Navigatorにしよう（全画面）
*   ８．デフォルトだとBtmNavi間の遷移でもTransitionがついてしまうので、Master部分はNoTransitionPageでくるむか
*     https://pub.dev/documentation/go_router/latest/go_router/NoTransitionPage-class.html
*   TODO 5/31 夜の作業はここから
* *   ９．違うタブに遷移した際に遷移元のタブの状態が残したい場合（StatefulShellRouteの考え方が必要）
*     https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html
*     https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stateful_shell_route.dart
*     => TODO これはmain.shell_routesをコピーしたmain.stateful_shell_routes.dartを作ってそこでやろう
*       （NormalDetailを開いた状態でWillPopタブに行ってNormalタブに戻った際にNormalDetailが表示されるようにしたい場合）
*       https://codewithandrea.com/articles/flutter-bottom-navigation-bar-nested-routes-gorouter-beamer/#the-navigation-state-of-each-tab-is-not-preserved
* */

void main() {
  WebUrlStrategy().setPathUrlStrategy();
  runApp(MyApp());
}

class ScreenPaths {
  //TODO １．ScreenPathsのパス変更（HomeScreenの各PageにもURLを付与するので「/」はなくなる）
  //  ルートのパスには「/」が必要だが、childRouteには「/」をつけてはいけない

  /*     BtmNavi
  * ---- normal(NormalPage => NormalMasterScreen) -- detail (NormalScreen => NormalDetailScreen)
  *   -- dialog(ShowDialogPage => ShowDialogMasterScreen) -- confirm_dialog(ConfirmDialog:変更なし）
  *   -- willPop(WillPopPage => WillPopMasterScreen) -- detail(WillPopScreen => WillPopDetailScreen)
  *     ** WillPopだけ画面全体にする
  * */

  static String normal = "/normal";
  static String normalDetail = "detail";

  static String dialog = "/dialog";
  static String confirmDialog = "confirm_dialog";

  static String willPop = "/will_pop";
  static String willPopDetail = "detail";

// static String home = "/";
// static String normal = "normal";
// static String willPop = "will_pop";
// static String confirmDialog = "confirm_dialog";
}

//TODO ４．NavigationのGlobalKeyを設定して３で作成したGoRoute群をShellRouteでくるむ
//https://codewithandrea.com/articles/flutter-bottom-navigation-bar-nested-routes-gorouter-beamer/#gorouter-implementation-with-shellroute
final _rootNavigateKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  //TODO ４．NavigationのGlobalKeyを設定して３で作成したGoRoute群をShellRouteでくるむ
  initialLocation: ScreenPaths.normal,
  navigatorKey: _rootNavigateKey,
  routes: [
    //TODO ４．NavigationのGlobalKeyを設定して３で作成したGoRoute群をShellRouteでくるむ
    //https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      //ScaffoldWithNavBarの部分は５で実装するので４の段階ではこれでいい
      //builder: (context, state, child) => HomeScreen(),
      //TODO ５．HomeScreenをScaffoldWithNavBarの内容に変更（ShellRoute#builderのchildを渡せるように）
      builder: (context, state, child) => HomeScreen(
        child: child,
      ),
      routes: [
        //TODO.3 HomeScreenのPage群もappRouterに加える（各Pageにもパスを付与）
        //TODO ４．NavigationのGlobalKeyを設定して３で作成したGoRoute群をShellRouteでくるんで"routes"に移動
        //Normal
        GoRoute(
          path: ScreenPaths.normal,
          //TODO ８．デフォルトだとBtmNavi間の遷移でもTransitionがついてしまうので、Master部分はNoTransitionPageでくるむか
          pageBuilder: (context, state) =>
              NoTransitionPage(child: NormalMasterScreen()),
          //builder: (context, state) => NormalMasterScreen(),
          routes: [
            GoRoute(
              path: ScreenPaths.normalDetail,
              pageBuilder: (context, state) {
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: NormalDetailScreen(),
                  transitionDuration: Duration(milliseconds: 500),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: CurveTween(curve: Curves.easeInOut)
                          .animate(animation),
                      //このchild忘れちゃだめよ（忘れると画面真っ白になるよ）
                      child: child,
                    );
                  },
                );
              },
            ),
          ],
        ),
        //ShowDialog
        GoRoute(
          path: ScreenPaths.dialog,
          //TODO ８．デフォルトだとBtmNavi間の遷移でもTransitionがついてしまうので、Master部分はNoTransitionPageでくるむか
          pageBuilder: (context, state) =>
              NoTransitionPage(child: ShowDialogMasterScreen()),
          //builder: (context, state) => ShowDialogMasterScreen(),
          routes: [
            GoRoute(
              path: ScreenPaths.confirmDialog,
              //builder(戻り値Widget）ではなくpageBuilder（戻り値pageBuilder）にする必要あり
              pageBuilder: (context, state) => DialogPage(
                builder: (_) => ConfirmDialog(),
              ),
            )
          ],
        ),
        //WillPop
        GoRoute(
          path: ScreenPaths.willPop,
          //TODO ８．デフォルトだとBtmNavi間の遷移でもTransitionがついてしまうので、Master部分はNoTransitionPageでくるむか
          pageBuilder: (context, state) =>
              NoTransitionPage(child: WillPopMasterScreen()),
          //builder: (context, state) => WillPopMasterScreen(),
          routes: [
            GoRoute(
              //TODO ７．画面全体に表示させるRouteに”parentNavigatorKey”を設定（WillPopDetailScreen）
              //This will cover both WillPopScreen and the application shell.
              //https://pub.dev/documentation/go_router/latest/go_router/GoRoute/parentNavigatorKey.html
              //https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html
              parentNavigatorKey: _rootNavigateKey,
              path: ScreenPaths.willPopDetail,
              builder: (context, state) {
                final param =
                    (state.extra != null) ? state.extra as String : "値なし";
                return WillPopDetailScreen(param: param);
              },
            )
          ],
        ),
      ],
    ),

    // GoRoute(
    //   path: ScreenPaths.home,
    //   builder: (context, state) => HomeScreen(),
    //   routes: [
    //     GoRoute(
    //       path: ScreenPaths.normal,
    //       pageBuilder: (context, state) {
    //         return CustomTransitionPage(
    //           key: state.pageKey,
    //           child: NormalDetailScreen(),
    //           transitionDuration: Duration(milliseconds: 500),
    //           transitionsBuilder:
    //               (context, animation, secondaryAnimation, child) {
    //             return FadeTransition(
    //               opacity:
    //                   CurveTween(curve: Curves.easeInOut).animate(animation),
    //               //このchild忘れちゃだめよ（忘れると画面真っ白になるよ）
    //               child: child,
    //             );
    //           },
    //         );
    //       },
    //     ),
    //     GoRoute(
    //       path: ScreenPaths.confirmDialog,
    //       //builder(戻り値Widget）ではなくpageBuilder（戻り値pageBuilder）にする必要あり
    //       pageBuilder: (context, state) => DialogPage(
    //         builder: (_) => ConfirmDialog(),
    //       ),
    //     ),
    //     GoRoute(
    //       path: ScreenPaths.willPop,
    //       builder: (context, state) {
    //         final param = (state.extra != null) ? state.extra as String : "値なし";
    //         return WillPopDetailScreen(param: param);
    //       },
    //     ),
    //   ],
    // ),
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

/// Builds the "shell" for the app by building a Scaffold with a
/// BottomNavigationBar, where [child] is placed in the body of the Scaffold.
class HomeScreen extends StatefulWidget {
  //TODO ５．HomeScreenをScaffoldWithNavBarの内容に変更（ShellRoute#builderのchildを渡せるように）
  /// The widget to display in the body of the Scaffold.
  /// In this sample, it is a Navigator.
  final Widget child;

  const HomeScreen({Key? key, required this.child}) : super(key: key);

  //const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //TODO ５．HomeScreenをScaffoldWithNavBarの内容に変更（ShellRoute#builderのchildを渡せるように）
  //  => indexは計算させる必要があるので
  //int _currentIndex = 0;

  //TODO ５．HomeScreenをScaffoldWithNavBarの内容に変更（ShellRoute#builderのchildを渡せるように）
  // final _pages = [
  //   NormalPage(),
  //   ShowDialogPage(),
  //   WillPopPage(),
  // ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //TODO ５．HomeScreenをScaffoldWithNavBarの内容に変更（ShellRoute#builderのchildを渡せるように）
      body: widget.child,
      //body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        //TODO ５．HomeScreenをScaffoldWithNavBarの内容に変更（ShellRoute#builderのchildを渡せるように）
        //  => indexは計算する必要あり
        currentIndex: _calcSelectedIndex(),
        onTap: (int index) => _onItemTapped(index),
        // currentIndex: _currentIndex,
        // onTap: (selectedIndex) {
        //   setState(() {
        //     _currentIndex = selectedIndex;
        //   });
        // },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.ad_units), label: "Normal"),
          BottomNavigationBarItem(icon: Icon(Icons.zoom_in), label: "Dialog"),
          BottomNavigationBarItem(icon: Icon(Icons.nat), label: "WillPop"),
        ],
      ),
    );
  }

  //TODO ５．HomeScreenをScaffoldWithNavBarの内容に変更（ShellRoute#builderのchildを渡せるように）
  //  => indexは計算する必要あり
  int _calcSelectedIndex() {
    final location = GoRouterState.of(context).location;
    if (location.startsWith(ScreenPaths.normal)) {
      return 0;
    }
    if (location.startsWith(ScreenPaths.dialog)) {
      return 1;
    }
    if (location.startsWith(ScreenPaths.willPop)) {
      return 2;
    }
    return 0;
  }

  //TODO ５．HomeScreenをScaffoldWithNavBarの内容に変更（ShellRoute#builderのchildを渡せるように）
  _onItemTapped(int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go(ScreenPaths.normal);
        break;
      case 1:
        GoRouter.of(context).go(ScreenPaths.dialog);
        break;
      case 2:
        GoRouter.of(context).go(ScreenPaths.willPop);
        break;
    }
  }
}

//------- １．Normal -------
//TODO ２．Page群・Screen群の名称変更(NormalPage => NormalMasterScreen)
class NormalMasterScreen extends StatelessWidget {
  const NormalMasterScreen({Key? key}) : super(key: key);

// class NormalPage extends StatelessWidget {
//   const NormalPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueAccent,
      child: Center(
        child: ElevatedButton(
          onPressed: () => _openNormalDetailScreen(context),
          child: Text("NormalScreenを開く"),
        ),
      ),
    );
  }

  //TODO ２．Page群・Screen群の名称変更
  _openNormalDetailScreen(BuildContext context) {
    //_openNormalScreen(BuildContext context) {
    //TODO goメソッドの行き先（引数）変更 => childRouteに行く際のgoメソッドはルートからのフルパスを指定する必要があるので引数変更
    //  （ルート部分の/は省いて（ScreenPathに入っているから）、ルートとサブの間に「/」を入れること: "/normal/detail"となるように）
    context.go("${ScreenPaths.normal}/${ScreenPaths.normalDetail}");
    print("_openNormalDetailScreen");
    //context.go("/${ScreenPaths.normal}");
  }
}

//TODO ２．Page群・Screen群の名称変更
class NormalDetailScreen extends StatelessWidget {
  const NormalDetailScreen({Key? key}) : super(key: key);

// class NormalScreen extends StatelessWidget {
//   const NormalScreen({Key? key}) : super(key: key);

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
          onPressed: () => _closeNormalDetailScreen(context),
          //onPressed: () => _closeNormalScreen(context),
          child: Text("もどる"),
        ),
      ),
    );
  }

  //TODO ２．Page群・Screen群の名称変更
  _closeNormalDetailScreen(BuildContext context) {
    //TODO goメソッドの行き先（引数）変更 => childRouteに行く際のgoメソッドはルートからのフルパスを指定する必要があるので引数変更
    context.go(ScreenPaths.normal);
    //context.go("/${ScreenPaths.home}");
  }
}

//------- ２．Dialog -------
//TODO ２．Page群・Screen群の名称変更
class ShowDialogMasterScreen extends StatelessWidget {
  const ShowDialogMasterScreen({Key? key}) : super(key: key);

// class ShowDialogPage extends StatelessWidget {
//   const ShowDialogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          //TODO goメソッドの行き先（引数）変更 => childRouteに行く際のgoメソッドはルートからのフルパスを指定する必要があるので引数変更
          //  （ルート部分の/は省いて（ScreenPathに入っているから）、ルートとサブの間に「/」を入れること: "/normal/detail"となるように）
          onPressed: () =>
              context.go("${ScreenPaths.dialog}/${ScreenPaths.confirmDialog}"),
          //onPressed: () => context.go("/${ScreenPaths.confirmDialog}"),
          child: Text("Dialogを開く"),
        ),
      ),
    );
  }
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
          onPressed: () => context.pop(),
          child: Text("とじる"),
        ),
      ],
    );
  }
}

//------- ３．WillPop -------
//TODO ２．Page群・Screen群の名称変更
class WillPopMasterScreen extends StatelessWidget {
  const WillPopMasterScreen({Key? key}) : super(key: key);

// class WillPopPage extends StatelessWidget {
//   const WillPopPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          onPressed: () => _openWillPopDetailScreen(context),
          child: Text("WillPopScreenを開く"),
        ),
      ),
    );
  }

  //TODO ２．Page群・Screen群の名称変更
  _openWillPopDetailScreen(BuildContext context) {
    //_openWillPopScreen(BuildContext context) {
    //TODO goメソッドの行き先（引数）変更 => childRouteに行く際のgoメソッドはルートからのフルパスを指定する必要があるので引数変更
    //  （ルート部分の/は省いて（ScreenPathに入っているから）、ルートとサブの間に「/」を入れること: "/normal/detail"となるように）
    context.go("${ScreenPaths.willPop}/${ScreenPaths.willPopDetail}",
        extra: "渡される値");
    //context.go("/${ScreenPaths.willPop}", extra: "渡される値");
  }
}

//TODO ２．Page群・Screen群の名称変更
class WillPopDetailScreen extends StatelessWidget {
//class WillPopScreen extends StatelessWidget {
  final String param;

  const WillPopDetailScreen({Key? key, required this.param}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      //https://api.flutter.dev/flutter/widgets/WillPopScope-class.html
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
              context.pop(true);
            },
            child: Text("閉じる"),
          ),
          TextButton(
            onPressed: () {
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

//go_routerだとDialogの表示のされ方がおかしいので、一工夫必要
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
