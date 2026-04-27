SL is a real-time, collaborative game engine and editor.

### Building and Running

Ensure Flutter (>= 3.41.7) and Dart (>= 3.11.5) is installed. https://docs.flutter.dev/install

The url the client connects to is currently hard coded. For running locally:
- `sl_editor/lib/pages/editor.dart` line `41`, replace the url with `localhost:8080`.
- `sl_editor/lib/client/client.dart` line `42`, replace `wss` with `ws`.

Build the editor by running:
```sh
cd sl_editor
flutter build web --no-wasm-dry-run --base-href /live/
```

You can build the server using:
```sh
cd sl_server
dart build cli
```
or skip this step and run it in debug mode later.

Create the following folder structure somewhere for the server to use:
```sh
root/
root/public/{editor_build_files}
```
Copy all files from `sl_editor/build/web/` into `root/public/`.

From the same working directory which contains `root/`, launch the server executable.
```sh
# assuming root/ is next to sl_server/

# if you built the server earlier on windows
./sl_server/build/cli/windows_x64/bundle/bin/main.exe

# otherwise
dart pub get -C sl_server
dart run sl_server/bin/main.dart
```
The editor is now available on `localhost:8080/live`
