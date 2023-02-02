import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Para eliminar la barra de estado
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import '../utils/constants.dart';
import '../utils/sign_service.dart';
import '../utils/user_settings.dart';
import '../utils/file_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SignalingService _hub = SignalingService();
  final settings = UserSettings();

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const appwhite = Colors.white38;
  static const appcolor = Color.fromARGB(44, 255, 255, 255);
  static const appagua = Colors.white54;
  static const appblack = Color.fromARGB(160, 56, 56, 56);

  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  final _mediaRecorder = MediaRecorder();

  bool _isLocalMirror = true;
  bool _showLocalStream = true;

  bool _inCalling = false;
  bool _isTorchOn = false;
  bool _isRecordingOn = false;
  String filePath = "";

  bool _showMarca = true;

  @override
  void initState() {
    super.initState();
    _hub.onConnectionStatusChanged = _onConnectionStatusChanged;

    _hub.onPeersReady = _onPeersReady;
    _hub.onRemoteStreamChanged = _onRemoteStreamChange;
    _hub.onLocalStreamChanged = _onLocalStreamChange;
    _hub.onRemoteCallCancel = _onRemoteCallHangUp;
    _hub.init();

    initRenderers(); //async
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hub.getLocalStream(MediaQuery.of(context).size);
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_inCalling) {
      _onRemoteCallHangUp('🗙 Llamada desactivada');
    }
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _hub.close();
  }

  @override
  Widget build(BuildContext context) {
    const double titleFontSize = 11 * 1.618033 * 3.1416;
    return Container(
      color: appcolor,
      child: Stack(children: [
        // Captura cámara local
        RotatedBox(
            quarterTurns: 0,
            child: RTCVideoView(
                _showLocalStream ? _localRenderer : _remoteRenderer,
                mirror: _isLocalMirror, //true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),
        // y por encima un scaffold
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,

              //statusBarBrightness: Brightness.light, // transparent status bar
              //statusBarIconBrightness: Brightness.dark, // status bar icons' color

              //systemNavigationBarColor: Colors.black, // navigation bar color
              //systemNavigationBarIconBrightness: Brightness.dark, //navigation bar icons' color
            ),

            //actions: <Widget>[Container()], //<- Oculta menu endDrawer
            actions: _buildAppBarActionButtonsYMenu(context),
          ),
          body: Stack(
            children: [
              // // MARCA DE AGUA
              if (_showMarca)
                Positioned(
                  //left: 0,
                  top: 30,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                      //widthFactor: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontFamily: 'LibreBodoni',
                              fontSize: titleFontSize,
                              //fontWeight: FontWeight.bold,
                              color: appagua,
                            ),
                            //textAlign: TextAlign.center,
                          ),
                          // Image.asset(
                          //   'assets/app_icon.png',
                          //   height: titleFontSize * .90,
                          //   width: titleFontSize * .90,
                          //   fit: BoxFit.contain,
                          //   color: const Color.fromARGB(222, 255, 255, 255),
                          //   colorBlendMode: BlendMode.dstOut,
                          // ),
                          // const Text(
                          //   'IN',
                          //   style: TextStyle(
                          //     fontFamily: 'LibreBodoni',

                          //     fontSize: titleFontSize,
                          //     //fontWeight: FontWeight.bold,
                          //     //color: Color.fromARGB(68, 255, 224, 152),
                          //     color: appagua,
                          //   ),
                          //   //textAlign: TextAlign.center,
                          // ),

                          // Image.asset(
                          //   'assets/app_logo.png',
                          //   // height: titleFontSize * 6,
                          //   width: titleFontSize * 5,
                          //   // fit: BoxFit.contain,
                          //   color: const Color.fromARGB(155, 255, 255, 255),
                          //   colorBlendMode: BlendMode.dstOut,
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_inCalling) ...[
                // REMOTO
                Positioned(
                  left: 30,
                  bottom: 30,
                  child: Transform.scale(
                    scale: 0.3,
                    alignment: Alignment.bottomLeft,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showLocalStream = !_showLocalStream;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: appwhite,
                          border: Border.all(
                            color: Colors.white,
                            width:
                                5, //                   <--- border width here
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: SizedBox(
                            width: getRTCVideoRendererWidht(),
                            height: 640,
                            child: RTCVideoView(getRTCVideoRenderer(),
                                mirror: getRTCVideoViewMirror(),
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitContain),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]
            ],
          ),
          endDrawer: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: _buildListinDrawer(context),
          ),
          floatingActionButton: _buildFloatingActionButtonBar(),
        ),
      ]),
    );
  }

  List<Widget> _buildAppBarActionButtonsYMenu(BuildContext context) {
    return <Widget>[
      // ESTADO HUB
      TextButton.icon(
        label: _inCalling
            ? Text(_hub.remoteInfo['alias'],
                style: const TextStyle(color: Colors.white))
            : const Text(''),
        icon: Icon(
          _hub.connected ? Icons.cloud_outlined : Icons.cloud_off,
          color: Colors.white,
        ),
        onPressed: _hub.reconnect,
        onLongPress: () {
          log('onLongPress');
          var _ctrlHub = TextEditingController(text: settings.signalingHost);
          var _ctrlUpload = TextEditingController(text: settings.uploadUrl);

          showDialog(
              context: context,
              builder: (context) =>
                  _buildDialogServidores(_ctrlHub, _ctrlUpload, context));
        },
      ),

      Expanded(child: Container()),
      // START STOP RECORDING AQUI
      if (_inCalling) //Quitar false
        Directionality(
          textDirection: TextDirection.rtl,
          child: TextButton.icon(
            label: Text(_isRecordingOn ? 'STOP' : 'START',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            icon: Icon(
              _isRecordingOn ? Icons.stop : Icons.fiber_manual_record,
              color: Colors.red,
            ),
            onPressed: _isRecordingOn ? _stopRecording : _startRecording,
          ),
        ),
      PopupMenuButton<String>(
        onSelected: (str) {}, //_selectAudioOutput,
        itemBuilder: (BuildContext context) {
          //List<PopupMenuEntry<String>> menu = [];
          final menu = <PopupMenuEntry<String>>[];

          // AQUI NO ENVIAR ARCHIVO
          // menu.add(
          //   PopupMenuItem<String>(
          //     value: 'upload',
          //     child: const Text('Enviar última grabación'),
          //     onTap: () async {
          //       showSnackBar(context, '📤 Envío iniciado');
          //       var result = await FileService().onPressedUploadFile();
          //       showSnackBar(context, result);
          //     },
          //   ),
          // );
          // menu.add(const PopupMenuDivider());
          menu.add(
            PopupMenuItem<String>(
              value: 'identificacion',
              child: const Text('Establecer identificación'),
              onTap: () {
                var localPeer = _hub.localInfo;
                var _controllerAlias =
                    TextEditingController(text: settings.alias);
                var _controllerDescripcion =
                    TextEditingController(text: settings.description);

                Future<void>.delayed(
                    const Duration(), // OR const Duration(milliseconds: 500),
                    () => showDialog(
                        context: context,
                        builder: (context) => _buildDialogIdentificacion(
                            _controllerAlias,
                            _controllerDescripcion,
                            localPeer,
                            context)));
              },
            ),
          );
          menu.add(
            PopupMenuItem<String>(
              value: 'agua',
              child:
                  Text((_showMarca ? 'Ocultar' : 'Mostrar') + ' marca de agua'),
              onTap: () async {
                setState(() {
                  _showMarca = !_showMarca;
                });
              },
            ),
          );
          //menu.add(const PopupMenuDivider());
          menu.add(
            PopupMenuItem<String>(
              value: 'about',
              child: const Text('Acerca de ...'),
              onTap: () {
                Future<void>.delayed(
                  const Duration(), // OR const Duration(milliseconds: 500),
                  () => _buildShowAboutDialog(context),
                );
              },
            ),
          );
          // LISTA DE media disponible
          // Para ver que media tenemos
          // if (_hub.mediaDevicesList != null) {
          //   menu.add(const PopupMenuDivider()); // as PopupMenuEntry<String>);
          //   //menu.addAll(_mediaDevicesList!
          //   menu.addAll(_hub.mediaDevicesList!
          //       //.where((device) => device.kind == 'audiooutput')
          //       .map((device) {
          //     return PopupMenuItem<String>(
          //       value: device.deviceId,
          //       child: Text(device.label),
          //     );
          //   }).toList());
          // }
          return menu;
        },
      ),
    ];
  }

  void _buildShowAboutDialog(BuildContext context) => showAboutDialog(
        context: context,
        applicationIcon: Image.asset(
          'assets/app_icon.png',
          height: 168 * .33,
          width: 168 * .33,
          fit: BoxFit.contain,
          // color: const Color.fromARGB(222, 255, 255, 255),
          // colorBlendMode: BlendMode.dstOut,
        ),
        applicationName: appName,
        applicationVersion: 'v1.0.7',
        //applicationLegalese: 'applicationLegalese',
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text('Entidades participantes\n')),
                  Image.asset(
                    'assets/logos.png',
                    height: 458 * .66,
                    width: 458 * .66,
                    fit: BoxFit.contain,
                    //color: const Color.fromARGB(222, 255, 255, 255),
                    //colorBlendMode: BlendMode.colorDodge,
                    //colorBlendMode: BlendMode.overlay,
                  ),
                ],
              ))
        ],
      );

  AlertDialog _buildDialogServidores(TextEditingController _ctrlHub,
          TextEditingController _ctrlUpload, BuildContext context) =>
      AlertDialog(
        title: const Text('Servidores remotos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ctrlHub,
              decoration: const InputDecoration(
                labelText: 'Signaling server',
                hintText: 'Indica la dirección del HUB',
              ),
            ),
            // TextField(
            //   controller: _ctrlUpload,
            //   decoration: const InputDecoration(
            //     labelText: 'Upload URL',
            //     hintText: 'Indica la dirección registro de Grabaciones',
            //   ),
            // ),
          ],
        ),
        actions: <Widget>[
          // TextButton(
          //     onPressed: () {
          //       _ctrlHub.text = wsserver;
          //       _ctrlUpload.text = uploadurl;
          //     },
          //     child: const Text('(Reset Cloud)')),
          TextButton(
              onPressed: () {
                settings.signalingHost = _ctrlHub.text;
                settings.uploadUrl = _ctrlUpload.text;
                _hub.reconnect();
                setState(() {});
                Navigator.pop(context);
                //Navigator.pop(context);
              },
              child: const Text('Aceptar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          )
        ],
      );

  Drawer _buildListinDrawer(BuildContext context) {
    var id = _hub.localInfo['peerid'];
    var remotePeers = _hub.pares.where((peer) => peer['peerid'] != id).toList();
    var localPeer = _hub.pares.firstWhere((peer) => peer['peerid'] == id,
        orElse: () => _hub.localInfo);
    var _controllerAlias = TextEditingController(text: settings.alias);
    var _controllerDescripcion =
        TextEditingController(text: settings.description);

    var tileAliasStyle = const TextStyle(
      color: Colors.white,
      overflow: TextOverflow.ellipsis,
      fontSize: 22,
      //fontWeight: FontWeight.bold,
    );

    var tileDescriptionStyle = const TextStyle(
      color: Colors.white54,
      overflow: TextOverflow.ellipsis,
      fontSize: 12,
      //fontWeight: FontWeight.bold,
    );

    return Drawer(
      //backgroundColor: const Color.fromARGB(160, 56, 56, 56),
      backgroundColor: appblack,

      child: Column(
        children: [
          // const SizedBox(
          //   height: 30,
          // ),
          // TITULO
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 15),
                Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'LibreBodoni',
                    color: appagua, //Colors.white38,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          // ME
          ListTile(
            onLongPress: () {
              showDialog(
                  context: context,
                  builder: (context) => _buildDialogIdentificacion(
                      _controllerAlias,
                      _controllerDescripcion,
                      localPeer,
                      context));
            },
            title: Text(
              localPeer['alias'],
              style: tileAliasStyle,
            ),
            subtitle: Text(
              localPeer['description'],
              style: tileDescriptionStyle,
            ),
            //trailing: const Icon(Icons.call_sharp, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40.0),
            ),
          ),
          const Divider(height: 1.0, color: appagua),
          //const Spacer(flex: 1),
          Expanded(
            flex: remotePeers.length,
            child: ListView.builder(
              shrinkWrap: true,
              reverse: true,
              itemCount: remotePeers.length,
              itemBuilder: (BuildContext context, int index) => Padding(
                padding: const EdgeInsets.all(2.0),
                child: ListTile(
                  // leading: const Icon(Icons.call_outlined,
                  //     color: Colors.white),

                  //tileColor: Color.fromARGB(201, 4, 152, 21),

                  title: Text(
                    "${remotePeers[index]['alias']}",
                    style: tileAliasStyle,
                  ),
                  subtitle: Text(
                    "${remotePeers[index]['description']}",
                    style: tileDescriptionStyle,
                  ),
                  trailing: remotePeers[index]['oncall']
                      ? const Icon(Icons.cancel_outlined, color: Colors.white54)
                      : const Icon(Icons.call_sharp, color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0),
                  ),
                  onTap: () {
                    if (!remotePeers[index]['oncall']) {
                      // MAKE CALL LLAMADA QUITAR COMENTARIO AQUI
                      _makeCall(remotePeers[index]);
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            //Para ajustar el siguiente botón abajo.
            flex: remotePeers.isNotEmpty ? 0 : 1,
            child: Container(),
          ),
          const SizedBox(height: 5),
          // CANCELAR DRAWER
          FloatingActionButton.extended(
            label: const Text('Cancelar'), // <-- Text
            backgroundColor: Colors.red,
            //icon: const Icon(Icons.arrow_back_rounded, size: 24.0),
            icon: const Icon(
              Icons.call_end_sharp,
              //size: 24.0,
            ),
            onPressed: () {
              Navigator.pop(context, true);
              //_hangUp();<-No cancelamos la llamada(es posible que estemos en una)
            },
          ),

          const SizedBox(height: 27)
        ],
      ),
    );
  }

  AlertDialog _buildDialogIdentificacion(
          TextEditingController _controllerAlias,
          TextEditingController _controllerDescripcion,
          localPeer,
          BuildContext context) =>
      AlertDialog(
        title: const Text('Identificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controllerAlias,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Indica un alias',
              ),
            ),
            TextField(
              controller: _controllerDescripcion,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Dame algún dato más',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          // ACEPTAR
          TextButton(
              onPressed: () {
                settings.alias = _controllerAlias.text;
                settings.description = _controllerDescripcion.text;
                localPeer['alias'] = settings.alias;
                localPeer['description'] = settings.description;
                _hub.setAlias(
                    _controllerAlias.text, _controllerDescripcion.text);
                setState(() {});
                Navigator.pop(context);
                //Navigator.pop(context);
              },
              child: const Text('Aceptar')),
          // CANCELAR
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          )
        ],
      );

  Widget _buildFloatingActionButtonBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // const SizedBox(width: 20),
            // // GRABAR
            // FloatingActionButton(
            //     child:
            //         Icon(_isRecordingOn ? Icons.stop : Icons.fiber_manual_record),
            //     onPressed: _isRecordingOn ? _stopRecording : _startRecording,
            //     foregroundColor: Colors.red,
            //     backgroundColor: Colors.white,
            //     mini: true),
            // Expanded(child: Container()),
            // FLASH
            FloatingActionButton(
              child: Icon(_isTorchOn ? Icons.flash_off : Icons.flash_on),
              onPressed: _toggleTorch,
            ),
            const SizedBox(width: 10),
            // CAMARA
            FloatingActionButton(
              child: const Icon(Icons.switch_video),
              onPressed: _toggleCamera,
            ),
            const SizedBox(width: 10),
            // LLAMADA
            FloatingActionButton(
                // onPressed: _inCalling ? _hangUp : _makeCall,
                onPressed: _hub.connected
                    ? _inCalling
                        ? _hub.cancelCall
                        : _hub.getSessions //_beginCall
                    : () {},
                //: _scaffoldKey.currentState?.openEndDrawer,
                tooltip: _inCalling ? 'Hangup' : 'Call',
                child: Icon(_inCalling ? Icons.call_end : Icons.phone),
                backgroundColor:
                    _inCalling || !_hub.connected ? Colors.red : Colors.green),
          ],
        ),
      );

  void _toggleTorch() async {
    //if (_localStream == null) throw Exception('Stream is not initialized');

    final videoTrack = _hub.localStream
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    final has = await videoTrack.hasTorch();
    if (has) {
      log('[TORCH] Current camera supports torch mode');
      setState(() => _isTorchOn = !_isTorchOn);
      await videoTrack.setTorch(_isTorchOn);
      log('[TORCH] Torch state is now ${_isTorchOn ? 'on' : 'off'}');
    } else {
      log('[TORCH] Current camera does not support torch mode');
    }
  }

  Future<void> _stopRecording() async {
    showSnackBar(context, 'Grabación finalizada');
    _isRecordingOn = false;
    await _mediaRecorder.stop();
    // Mover filePath a galeria
    await saveRecordedVideoToGallery(videoPath: filePath);
    await removeDownloadedVideo(videoPath: filePath);
    filePath = "";
    setState(() {});
  }

  void _startRecording() async {
    showSnackBar(context, 'Grabación iniciada');

    _isRecordingOn = true;

    // final storagePath = await getExternalStorageDirectory();
    // if (storagePath == null) throw Exception('Can\'t find storagePath');

    //  filePath = storagePath.path + '/ikuzain.mp4';
    filePath = await FileService().getName();
    //"/storage/emulated/0/Android/data/com.fstrange.fretece/files/"
    final videoTrack = _hub.localStream
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');

    await _mediaRecorder.start(
      filePath,
      videoTrack: videoTrack,
      audioChannel: RecorderAudioChannel.INPUT,
    );
    setState(() {});
  }

  Future<void> saveRecordedVideoToGallery({required String videoPath}) async {
    await ImageGallerySaver.saveFile(videoPath, name: p.basename(videoPath));
  }

  Future<void> removeDownloadedVideo({required String videoPath}) async {
    try {
      Directory(videoPath).deleteSync(recursive: true);
    } catch (error) {
      debugPrint('$error');
    }
  }

  void _toggleCamera() async {
    //if (_localStream == null) throw Exception('Stream is not initialized');

    final videoTrack = _hub.localStream
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');

    try {
      await Helper.switchCamera(videoTrack);
      _isLocalMirror = await videoTrack.hasTorch() ? false : true;
      setState(() {});
      log('[CAMERA] ${_isLocalMirror ? 'FRONT' : 'BACK'}');

      //Back camera sin mirror
    } catch (e) {
      //
    }
  }

  void _makeCall(dynamic remote) async {
    setState(() {
      //status = remote['alias'];
      _hub.makeCall(remote['peerid']);
      _inCalling = true;
    });
  }

  void _onRemoteCallHangUp(String msg) async {
    if (_isRecordingOn) await _stopRecording();
    try {
      // desconectamos nuestro streamlocal

      // if (kIsWeb) {
      //   _localStream?.getTracks().forEach((track) => track.stop());
      // }
      // quitamos la presentación remota
      _remoteRenderer.srcObject = null;

      setState(() {
        _inCalling = false;
        _showLocalStream = true;
      });
      showSnackBar(context, msg);
    } catch (e) {
      //
    }
  }

  // MANEJO DE LA CONEXION Y LISTA DE PARES
  void _onPeersReady() {
    //_scaffoldKey.currentState?.openEndDrawer();
    setState(() {
      _inCalling = false;
      _scaffoldKey.currentState?.openEndDrawer();
    });
  }

  void _onConnectionStatusChanged() {
    // Obliga a repintar el ActionButton de la NUBE
    // El estado de la conexión con el HUB ha cambiado
    setState(() {});
  }

  // MANEJO DE LOS STREAMS
  void _onRemoteStreamChange(MediaStream stream) {
    setState(() {
      _inCalling = true;
      _remoteRenderer.srcObject = stream;
    });
  }

  void _onLocalStreamChange(MediaStream stream) {
    _localRenderer.srcObject = stream;

    setState(() {});
  }

  void initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    // _mediaDevicesList = await _hub.getMediaDevices();

    setState(() {});
  }

  // MENSAJE DE INFORMACIÓN
  void showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: appblack,

        action: SnackBarAction(
          label: 'Cerrar',
          onPressed: () {
            // Code to execute.
          },
        ),
        duration: const Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
        //backgroundColor: const Color(0xFFED872D),
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0, // Inner padding for SnackBar content.
        ),
        shape: RoundedRectangleBorder(
            //side: const BorderSide(color: Colors.pink, width: 2),
            borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  RTCVideoRenderer getRTCVideoRenderer() {
    //     const double titleFontSize = 11 * 1.618033 * 3.1416;
    return !_showLocalStream ? _localRenderer : _remoteRenderer;
  }

  bool getRTCVideoViewMirror() {
    return !_showLocalStream ? _isLocalMirror : true;
  }

  double getRTCVideoRendererWidht() {
    if (_inCalling) return 640 * 9 / 16;
    var renderer = getRTCVideoRenderer();
    return 640 * renderer.videoHeight / renderer.videoWidth;
  }
}
