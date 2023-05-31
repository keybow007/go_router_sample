import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web_url_strategy/web_url_strategy.dart';

/*
* <go_routerバージョン４：StategulShellRoutes>
*   => バージョン３（main.shell_routes.dart）をコピー
*
*   ShellRoutesだと、遷移元のタブの状態がクリアされてしまう
*   （NormalタブでNormalDetailScreenを開いてから別のタブに行って戻ってきたらNormalMasterScreenになっている）
*   => 違うタブに遷移した際に遷移元のタブの状態が残したい場合（StatefulShellRouteの考え方が必要）
*     https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html
*     https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stateful_shell_route.dart
*     => これはmain.shell_routesをコピーしたmain.stateful_shell_routes.dartを作ってそこでやろう
*       （NormalDetailを開いた状態でWillPopタブに行ってNormalタブに戻った際にNormalDetailが表示されるようにしたい場合）
*       https://codewithandrea.com/articles/flutter-bottom-navigation-bar-nested-routes-gorouter-beamer/#the-navigation-state-of-each-tab-is-not-preserved
*
*   ＜進め方＞
*   １．ShellRoute => StatefulShellRoute.indexedStackに
*       ・
*
*
*
* */

void main() {
  WebUrlStrategy().setPathUrlStrategy();
  runApp(MyApp());
}

class ScreenPaths {
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
}

//https://codewithandrea.com/articles/flutter-bottom-navigation-bar-nested-routes-gorouter-beamer/#gorouter-implementation-with-shellroute
final _rootNavigateKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: ScreenPaths.normal,
  navigatorKey: _rootNavigateKey,
  routes: [
    /*
    * TODO 1. ShellRoute => StatefulShellRoute.indexedStackに
    *  https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html
    *  https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute/StatefulShellRoute.indexedStack.html
    *   ・ShellRoute#routes => StatefulShellRoute.indexedStack#branchesに
    * TODO 2  各タブのGoRouteをStatefulShellBranchでくるむ
    *   https://pub.dev/documentation/go_router/latest/go_router/StatefulShellBranch-class.html
    *     => タブごとにbranch(StatefulShellBranch)が切られる（正確には状態管理を分ける単位ごとにbranchを作る）
    *     => 各branchにはデフォルトでnavigateKeyが設定されるのでShellRouteでやったような_shellNavigateKeyを自分で設定する必要なし
    *
    * TODO 3. HomeScreenに入れる引数をchild(Widget) => navigationShell(StatefulNavigationShell)に
    *  https://pub.dev/documentation/go_router/latest/go_router/StatefulNavigationShell-class.html
    *   （引数名は「child」のままでもいいかもしれないが）
    *
    * TODO 4. HomeScreenのBtmNavi部分の変更①：currentIndex : indexの計算メソッド => navigationShell.currentIndexに
    *
    * TODO 5. HomeScreenのBtmNavi部分の変更②：onTap: navigationShell.goBranchに
    *
    * TODO 6. (optional) 状態管理はNavigationShellがやってくれるのでHomeScreen自体はStatelessWidgetにしても問題ない
    *
    *  TODO 7. navigationShell.goBranchメソッドでinitialLocationを設定する場合（公式のサンプル176行目より）
    *   https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stateful_shell_route.dart
    *
    *
    * */
    //TODO.1  ShellRoute => StatefulShellRoute.indexedStackに
    StatefulShellRoute.indexedStack(
      //ShellRoute(
      //navigatorKey: _shellNavigatorKey,
      //TODO 3. HomeScreenに入れる引数をchild(Widget) => navigationShell(NavigationSHell)に
      builder: (context, state, navigationShell) => HomeScreen(navigationShell: navigationShell),
      //builder: (context, state, child) => HomeScreen(child: child),
      branches: [
        //routes: [
        //Normal
        //TODO 2  各タブのGoRouteをStatefulShellBranchでくるむ
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: ScreenPaths.normal,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: NormalMasterScreen()),
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
                          child: child,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        //ShowDialog
        //TODO 2  各タブのGoRouteをStatefulShellBranchでくるむ
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: ScreenPaths.dialog,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: ShowDialogMasterScreen()),
              routes: [
                GoRoute(
                  path: ScreenPaths.confirmDialog,
                  pageBuilder: (context, state) => DialogPage(
                    builder: (_) => ConfirmDialog(),
                  ),
                )
              ],
            ),
          ],
        ),
        //WillPop
        //TODO 2  各タブのGoRouteをStatefulShellBranchでくるむ
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: ScreenPaths.willPop,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: WillPopMasterScreen()),
              routes: [
                GoRoute(
                  //This will cover both WillPopScreen and the application shell.
                  //https://pub.dev/documentation/go_router/latest/go_router/GoRoute/parentNavigatorKey.html
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
      ],
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

/// Builds the "shell" for the app by building a Scaffold with a
/// BottomNavigationBar, where [child] is placed in the body of the Scaffold.
class HomeScreen extends StatefulWidget {

  //TODO 3. HomeScreenに入れる引数をchild(Widget) => navigationShell(NavigationSHell)に
  final StatefulNavigationShell navigationShell;
  //final Widget child;

  //TODO 3. HomeScreenに入れる引数をchild(Widget) => navigationShell(NavigationSHell)に
  const HomeScreen({Key? key, required this.navigationShell}) : super(key: key);
  //const HomeScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //TODO 3. HomeScreenに入れる引数をchild(Widget) => navigationShell(NavigationSHell)に
      body: widget.navigationShell,
      //body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        //TODO 4. HomeScreenのBtmNavi部分の変更①：currentIndex : indexの計算メソッド => navigationShell.currentIndexに
        currentIndex: widget.navigationShell.currentIndex,
        //currentIndex: _calcSelectedIndex(),
        //TODO 5. HomeScreenのBtmNavi部分の変更②：onTap: navigationShell.goBranchに
        onTap: (int index) => widget.navigationShell.goBranch(index),
        //onTap: (int index) => _onItemTapped(index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.ad_units), label: "Normal"),
          BottomNavigationBarItem(icon: Icon(Icons.zoom_in), label: "Dialog"),
          BottomNavigationBarItem(icon: Icon(Icons.nat), label: "WillPop"),
        ],
      ),
    );
  }

  //TODO 4. HomeScreenのBtmNavi部分の変更①：currentIndex : indexの計算メソッド => navigationShell.currentIndexに
  // int _calcSelectedIndex() {
  //   final location = GoRouterState.of(context).location;
  //   if (location.startsWith(ScreenPaths.normal)) {
  //     return 0;
  //   }
  //   if (location.startsWith(ScreenPaths.dialog)) {
  //     return 1;
  //   }
  //   if (location.startsWith(ScreenPaths.willPop)) {
  //     return 2;
  //   }
  //   return 0;
  // }

  //TODO 5. HomeScreenのBtmNavi部分の変更②：onTap: navigationShell.goBranchに
  // _onItemTapped(int index) {
  //   switch (index) {
  //     case 0:
  //       GoRouter.of(context).go(ScreenPaths.normal);
  //       break;
  //     case 1:
  //       GoRouter.of(context).go(ScreenPaths.dialog);
  //       break;
  //     case 2:
  //       GoRouter.of(context).go(ScreenPaths.willPop);
  //       break;
  //   }
  // }
}

//------- １．Normal -------
class NormalMasterScreen extends StatelessWidget {
  const NormalMasterScreen({Key? key}) : super(key: key);

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

  _openNormalDetailScreen(BuildContext context) {
    context.go("${ScreenPaths.normal}/${ScreenPaths.normalDetail}");
  }
}

class NormalDetailScreen extends StatelessWidget {
  const NormalDetailScreen({Key? key}) : super(key: key);

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
          child: Text("もどる"),
        ),
      ),
    );
  }

  _closeNormalDetailScreen(BuildContext context) {
    context.go(ScreenPaths.normal);
  }
}

//------- ２．Dialog -------
class ShowDialogMasterScreen extends StatelessWidget {
  const ShowDialogMasterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          onPressed: () =>
              context.go("${ScreenPaths.dialog}/${ScreenPaths.confirmDialog}"),
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
class WillPopMasterScreen extends StatelessWidget {
  const WillPopMasterScreen({Key? key}) : super(key: key);

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

  _openWillPopDetailScreen(BuildContext context) {
    context.go("${ScreenPaths.willPop}/${ScreenPaths.willPopDetail}",
        extra: "渡される値");
  }
}

class WillPopDetailScreen extends StatelessWidget {
  final String param;

  const WillPopDetailScreen({Key? key, required this.param}) : super(key: key);

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
