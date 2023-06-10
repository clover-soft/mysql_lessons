import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

const String _host = '192.168.2.100';
const int _port = 3306;
const String _user = 'crud_demo';
const String _password = '12345678';
const String _database = 'lesson_2';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'демонстрируем CRUD операции с MySQL',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'CRUD приложенька'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final MySqlConnection _conn;

  List<Map<String, dynamic>> _items = [];

  final _textController = TextEditingController();

  int? _selectedIndex;

  Future<void> _openConnection() async {
    _conn = await MySqlConnection.connect(ConnectionSettings(
      host: _host,
      port: _port,
      user: _user,
      password: _password,
      db: _database,
    ));

    await _conn.query(
        'CREATE TABLE IF NOT EXISTS items (id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(50))');

    await _getItems();
  }

  Future<void> _getItems() async {
    final result = await _conn.query('SELECT * FROM items');

    _items = result.map((e) => e.fields).toList();

    setState(() {});
  }

  Future<void> _addItem(String name) async {
    await _conn.query('INSERT INTO items (name) VALUES (?)', [name]);

    await _getItems();
  }

  Future<void> _editItem(int id, String name) async {
    await _conn.query('UPDATE items SET name = ? WHERE id = ?', [name, id]);

    await _getItems();
  }

  Future<void> _deleteItem(int id) async {
    await _conn.query('DELETE FROM items WHERE id = ?', [id]);

    await _getItems();
  }

  @override
  void initState() {
    super.initState();
    _openConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(item['name']),
            onTap: () async {
              _textController.text = item['name'];
              final result = await showDialog<String>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Редактировать'),
                    content: TextField(
                      controller: _textController,
                      autofocus: true,
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, _textController.text);
                        },
                        child: Text('Сохранить'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, null);
                        },
                        child: Text('Отмена'),
                      ),
                    ],
                  );
                },
              );
              if (result != null) {
                await _editItem(item['id'], result);
              }
            },
            selected: _selectedIndex == index,
            onLongPress: () {
              setState(() {
                _selectedIndex = index;
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _textController.text = '';
          final result = await showDialog<String>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Добавить запись'),
                content: TextField(
                  controller: _textController,
                  autofocus: true,
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _textController.text);
                    },
                    child: Text('Добавить'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, null);
                    },
                    child: Text('Отменить'),
                  ),
                ],
              );
            },
          );
          if (result != null) {
            await _addItem(result);
          }
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: _selectedIndex == null
                  ? null
                  : () async {
                      _textController.text = _items[_selectedIndex!]['name'];
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Редактируем запись'),
                            content: TextField(
                              controller: _textController,
                              autofocus: true,
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, _textController.text);
                                },
                                child: Text('Сохранить'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, null);
                                },
                                child: Text('Отмена'),
                              ),
                            ],
                          );
                        },
                      );
                      if (result != null) {
                        await _editItem(_items[_selectedIndex!]['id'], result);
                      }
                    },
              child: Text('Редактировать'),
            ),
            ElevatedButton(
              onPressed: _selectedIndex == null
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Удалить запись'),
                            content:
                                Text('Вы увереный что хотите удалить запись?'),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: Text('Да'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: Text('Нет'),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirmed != null && confirmed) {
                        await _deleteItem(_items[_selectedIndex!]['id']);
                      }
                    },
              child: Text('Удалить'),
            ),
          ],
        ),
      ),
    );
  }
}
