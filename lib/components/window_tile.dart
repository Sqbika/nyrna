import 'package:flutter/material.dart';
import 'package:nyrna/process.dart';
import 'package:nyrna/window.dart';
import 'package:provider/provider.dart';

class WindowTile extends StatefulWidget {
  final Window window;

  WindowTile({this.window});

  @override
  _WindowTileState createState() => _WindowTileState();
}

class _WindowTileState extends State<WindowTile> {
  Process process;
  Window window;

  @override
  void initState() {
    super.initState();
    window = widget.window;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    process = Provider.of<Process>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _toggle(),
      child: Consumer<Process>(builder: (context, process, widget) {
        var _icon = process.status == 'suspended'
            ? Icons.flag_outlined
            : Icons.run_circle;

        Color backgroundColor =
            process.status == 'suspended' ? Colors.blueGrey : null;

        return Card(
          color: backgroundColor,
          child: ListTile(
            leading: Icon(_icon),
            title: Text(window.title),
            contentPadding: EdgeInsets.symmetric(
              vertical: 2,
              horizontal: 20,
            ),
          ),
        );
      }),
    );
  }

  _toggle() {
    bool successful = process.toggle(); // TODO: Notify of failure.
    // setState(() => backgroundColor = successful ? Colors.blueGrey : null);
    // if (!successful) setState(() => backgroundColor = Colors.red);
    if (successful && true) _toggleWindow(); // TODO: Option for window minimize
  }

  _toggleWindow() {
    if (process.status == 'suspended') {
      window.minimize();
    } else {
      window.restore();
    }
  }
}
