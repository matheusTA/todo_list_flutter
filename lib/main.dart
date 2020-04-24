import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    title: 'Lista de tarefas',
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemmovedPosition;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();

      newToDo['title'] = _toDoController.text;
      _toDoController.text = '';
      newToDo['isFinish'] = false;

      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((prev, next) {
        if (prev['isFinish'] && !next['isFinish'])
          return 1;
        else if (!prev['isFinish'] && next['isFinish'])
          return -1;
        else
          return 0;
      });
      _saveData();
    });

    return null;
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(
          _toDoList[index]['title'],
          style: TextStyle(fontSize: 20.0),
        ),
        value: _toDoList[index]['isFinish'],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['isFinish'] ? Icons.check : Icons.error),
        ),
        onChanged: (isCheck) {
          setState(() {
            _toDoList[index]['isFinish'] = isCheck;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemmovedPosition = index;
          _toDoList.removeAt(index);

          _saveData();

          final snackbar = SnackBar(
            content: Text('Tarefa ${_lastRemoved['title']} removida!'),
            action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemmovedPosition, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snackbar);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista de Tarefas',
          style: TextStyle(fontSize: 25.0),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 10.0, 17.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    style: TextStyle(fontSize: 20.0),
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: 'Nova tarefa*',
                        labelStyle: TextStyle(
                            color: Colors.blueAccent, fontSize: 25.0)),
                  ),
                ),
                FloatingActionButton(
                  onPressed: _addToDo,
                  tooltip: 'Increment',
                  child: Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem),
          ))
        ],
      ),
    );
  }
}
