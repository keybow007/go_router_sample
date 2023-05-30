import 'package:flutter/material.dart';

/*
* <Navigatorバージョン>
* １．Normal : NormalPage => NormalScreenを開く
* ２．Dialog : DialogPage => showDialogでAlertDialogを開く
* ３．WillPop: WillPopPage => WillPopScreenを開く（引数渡しも）閉じる際にWillPop
* https://pub.dev/documentation/go_router/latest/topics/Navigation-topic.html#prevent-navigation
*   => WillPopScopeはAndroidデバイスの戻るボタンを押してもWorkするが、これをgo_routerではできないそうだ
*
* TODO Navigatorからgo_routerへの歴史的背景を公式を使って説明しよう
*  （なぜNamedRouteはダメなのかも含めて）
*  https://docs.flutter.dev/ui/navigation
* */

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NormalScreen(),
      ),
    );
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
    Navigator.pop(context);
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
          onPressed: () => _openDialog(context),
          child: Text("Dialogを開く"),
        ),
      ),
    );
  }

  _openDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ダイアログ"),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text("とじる"),
          ),
        ],
      ),
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
    Navigator.push(
      context,
      //Screenを開く際に値渡し
      MaterialPageRoute(
        builder: (_) => WillPopScreen(
          param: "渡された値",
        ),
      ),
    );
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
    final isConfirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text("画面を閉じていいですか？"),
        actions: [
          TextButton(
            onPressed: () {
              //ダイアログを閉じて戻り値を返している
              // （onWillPopの戻り値がtrueになるのでit's OK to call [Navigator.pop]）
              Navigator.pop(context, true);
            },
            child: Text("閉じる"),
          ),
          TextButton(
            onPressed: () {
              //ダイアログを閉じて戻り値を返している
              // （onWillPopの戻り値がfalseになるのでNavigator.popが発動されない）
              Navigator.pop(context, false);
            },
            child: Text("キャンセル"),
          ),
        ],
      ),
    );
    return isConfirmed;
  }
}
