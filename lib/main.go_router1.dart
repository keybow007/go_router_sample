import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web_url_strategy/web_url_strategy.dart';

/*
* <go_routerバージョン：まずは親子方式（GoRouteのpathに「/」不要）>
*   => TODO 親子方式の場合、画面遷移は原則全て「go」メソッド
*     （Config時（appRouter）に親子関係を一元管理させておく
*       => 「Go」Routerの思想に沿って）
*       => appRouterで画面遷移の家系図を予め宣言的に記述しておけば、
*          goメソッドはその家系図に従って自動的にpush/popしてくれる
*           （家系図に沿った画面遷移をしてくれる）
*
* １．Normal : NormalPage => NormalScreenを開く
* ２．Dialog : DialogPage => showDialogでAlertDialogを開く
* ３．WillPop: WillPopPage => WillPopScreenを開く（引数渡しも）閉じる際にWillPop
* https://pub.dev/documentation/go_router/latest/topics/Navigation-topic.html#prevent-navigation
*   => WillPopScopeはAndroidデバイスの戻るボタンを押してもWorkするが、これをgo_routerではできないそうだ
*
* ShellRouteはとりあえずはやらない
* 複数のRouteを使いたい場合ShellRouteってやつを使うらしい（Nested Navigation）
* https://pub.dev/documentation/go_router/latest/topics/Configuration-topic.html#nested-navigation
* （例：BtmNaviでbodyの部分だけアプリ全体のNavigatorとは別のNavigatorを使いたい場合（=>BtMNavi部分を残したまま子Pageから別の画面を開きたい場合）
* https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html
*   これもAndreaの良記事
*   https://codewithandrea.com/articles/flutter-bottom-navigation-bar-nested-routes-gorouter-beamer/
*
*  ＜進め方＞
*   １．まずはNavigatorの部分をgo_routerに変える（
*   ２．DialogPageのDialogをshowDialogからgo_router使えるようにWidget化
*   ３．Dialogの表示のされ方がおかしいので、一工夫必要だが面倒なので省略
*     （ダイアログにURLがいらんねやったら、もうshowDialogでええんちゃうか？
*       => チュートリアルだけ紹介して本編での実装は省略）
*     https://stackoverflow.com/questions/75690299/how-do-i-show-a-dialog-in-flutter-using-a-go-router-route
*     https://croxx5f.hashnode.dev/adding-modal-routes-to-your-gorouter
*   ４．builderとpageBuilderの違い（pageBuilderはアニメーションがつけられる）
*     => NormalScreenでやってみよう
*     https://pub.dev/documentation/go_router/latest/topics/Transition%20animations-topic.html
*   ５．PathStrategyを変える（#を省く）=>私の自作パッケージ使おう
*     https://docs.flutter.dev/ui/navigation/url-strategies
*     https://github.com/keybow007/web_url_strategy
*
* TODO なぜgoが宣言的（Declarative）でpush/popが命令的（imperative）なのか
*  => goを使う場合は予め階層関係（親子関係）が明示されているから
*  => push/popは命令時に親子関係を設定するから
*   ということだろうか？？
*   https://pub.dev/documentation/go_router/latest/topics/Navigation-topic.html
* */

void main() {
  //TODO[go_router.5]UrlStrategyの変更（#を省く）=>私の自作パッケージ使おう
  //https://docs.flutter.dev/ui/navigation/url-strategies
  //https://github.com/keybow007/web_url_strategy
  WebUrlStrategy().setPathUrlStrategy();
  runApp(MyApp());
}

//TODO[go_router.1]goメソッドで使うパスの設定
class ScreenPaths {
  //親子方式の場合はGoRouteのpathに「/」不要
  static String home = "/";
  static String normal = "normal";
  static String willPop = "will_pop";

  //TODO[go_router.2]DialogもNavigatorで開かれるScreenなのでRouteに加える
  static String confirmDialog = "confirm_dialog";
}

//TODO[go_router1.]Routerの設定（画面遷移の家系図）
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: ScreenPaths.home,
      builder: (context, state) => HomeScreen(),
      routes: [
        GoRoute(
          path: ScreenPaths.normal,
          //builder: (context, state) => NormalScreen(),
          //TODO[go_router.4]カスタムTransitionアニメーション（pageBuilder）
          //https://pub.dev/documentation/go_router/latest/topics/Transition%20animations-topic.html
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: NormalScreen(),
              transitionDuration: Duration(milliseconds: 500),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity:
                      CurveTween(curve: Curves.easeInOut).animate(animation),
                  //このchild忘れちゃだめよ（忘れると画面真っ白になるよ）
                  child: child,
                );
              },
            );
          },
        ),
        //TODO[go_router.2]DialogもNavigatorで開かれるScreenなのでRouteに加える（ただしこのままだとトラップ有り）
        GoRoute(
          path: ScreenPaths.confirmDialog,
          builder: (context, state) => ConfirmDialog(),
        ),
        GoRoute(
          path: ScreenPaths.willPop,
          //TODO[go_route.1]値渡しの方法(extraを使おう: extraはObjectなのでなんでもいい。）
          //https://pub.dev/documentation/go_router/latest/topics/Configuration-topic.html#Parameters
          //pathParametersとqueryParametesの違いにも言及しよう（TODO 値渡し３つの方法にも言及しよう）
          //https://stackoverflow.com/a/74813803/7300575
          builder: (context, state) {
            //goメソッドのextraはObjectなので、何でもいい
            //  => この段階でWillPopScreenに渡す前に適切な型変換をしてやればいい
            final param = (state.extra != null) ? state.extra as String : "値なし";
            return WillPopScreen(param: param);
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //TODO[go_router.1]MaterialApp.routerに
    return MaterialApp.router(
      routerConfig: appRouter,
    );
    // return MaterialApp(
    //   home: HomeScreen(),
    // );
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
    DialogPage(),
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
    //TODO [go_router.1]親子方式の場合はgoの引数に「/」必要
    context.go("/${ScreenPaths.normal}");

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => NormalScreen(),
    //   ),
    // );
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
    //TODO [go_router.1]親子方式の場合はgoの引数に「/」必要
    context.go("/${ScreenPaths.home}");

    //Navigator.pop(context);
  }
}

//------- ２．Dialog -------
class DialogPage extends StatelessWidget {
  const DialogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          //TODO [go_router.2]showDialogはpagelessなので、go_router経由で開く
          onPressed: () => context.go("/${ScreenPaths.confirmDialog}"),
          //onPressed: () => _openDialog(context),
          child: Text("Dialogを開く"),
        ),
      ),
    );
  }

  _openDialog(BuildContext context) {
    /*
    * TODO [go_router.2]showDialogで開かれる画面は"pageless"なので、go_routerはWorkしない
    * https://docs.flutter.dev/ui/navigation#using-router-and-navigator-together
    * => go_routerから開くのでDialogを別クラスにする必要あり
    * => _openDialogは結果的に使わなくなる
    * */

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ダイアログ"),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            //TODO [go_router.1]
            //onPressed: () => Navigator.pop(context),
            onPressed: () => context.pop(context),
            child: Text("とじる"),
          ),
        ],
      ),
    );
  }
}

//TODO[go_router.2]Dialogをgo_routerで開くので別クラスにする必要あり
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
          //TODO[go_router]ここはcontext.go/pop両方Workするみたい（appRouterで親子関係つけてるので）
          // => goの場合はDialogの乗っかったWillPopScreenからHomeScreenに
          //    Replaceさせているので結果的にDialogを閉じた格好となっている
          // => 何回が他のBtmNaviを行ったり来たりするとWorkしなくなるので
          // => popの方がよさそう
          //onPressed: () => context.go("/${ScreenPaths.home}"),
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
    //TODO[go_router]値渡しの方法（extraを使おう（extraはObjectなのでなんでもいい=> GoRouteのbuilderで適切な型変換が必要）
    //  => goNamedの場合はpathではなくnameを設定する必要があるので「/」は要らない
    //https://pub.dev/documentation/go_router/latest/topics/Configuration-topic.html#Parameters
    //https://stackoverflow.com/a/74813803/7300575
    context.go("/${ScreenPaths.willPop}", extra: "渡される値");
    // context.goNamed(
    //   "${ScreenPaths.willPop}",
    //   queryParameters: {"param": "渡される値"},
    // );

    // Navigator.push(
    //   context,
    //   //Screenを開く際に値渡し
    //   MaterialPageRoute(
    //     builder: (_) => WillPopScreen(
    //       param: "渡された値",
    //     ),
    //   ),
    // );
  }
}

class WillPopScreen extends StatelessWidget {
  final String param;

  const WillPopScreen({Key? key, required this.param}) : super(key: key);

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
    /*
    * TODO[go_router]WillPopScopeはWorkしない模様
    *  https://github.com/flutter/flutter/issues/99706
    *   WillPopScope only works with to Navigator.pop(), not GoRouter.of(context).go().
    *   ただし、showDialogで
    *     ・閉じる場合にcontext.go(home)を使って
    *     ・キャンセルの場合にcontext.popが使えないのでNavigator.popにすると
    *   キャンセルした際に「Unhandled Exception: type 'Null' is not a subtype of type 'FutureOr<bool>'」
    *   というエラーが出て結局Home画面に戻ってしまった
    *   => Dialogを閉じる場合はYesの場合もNavigator.popにしないといけないみたい
    *       （showDialogで開いた画面はpagelessなので）
    *      https://docs.flutter.dev/ui/navigation#using-router-and-navigator-together
    * */

    //TODO[go_router]このダイアログは面倒なのでWidgetクラス化しない（go_router使わない）
    final isConfirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text("画面を閉じていいですか？"),
        actions: [
          TextButton(
            onPressed: () {
              //ダイアログを閉じて戻り値を返している
              // （onWillPopの戻り値がtrueになるのでit's OK to call [Navigator.pop]）
              //TODO[go_router]ここはcontext.go/pop両方Workするみたい
              // => goの場合はDialogの乗っかったWillPopScreenからHomeScreenに
              //    Replaceさせているので結果的にDialogを閉じた格好となっている
              // => 何回が他のBtmNaviを行ったり来たりするとWorkしなくなるので
              // => popの方がよさそう
              //context.go("/${ScreenPaths.home}");
              context.pop(true);
              //Navigator.pop(context, true);
            },
            child: Text("閉じる"),
          ),
          TextButton(
            onPressed: () {
              //ダイアログを閉じて戻り値を返している
              // （onWillPopの戻り値がfalseになるのでNavigator.popが発動されない）
              //TODO[go_router]context.pop使えた（戻り値の返し方）
              //https://pub.dev/documentation/go_router/latest/topics/Navigation-topic.html#returning-values
              context.pop(false);
              //これだとDialogは閉じない（showDialogで開いた画面はpagelessなので）
              //context.go("/${ScreenPaths.willPop}");
              //Navigator.pop(context, false);
            },
            child: Text("キャンセル"),
          ),
        ],
      ),
    );
    return isConfirmed;
  }
}
