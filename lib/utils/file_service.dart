import 'dart:developer';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'user_settings.dart';

class FileService {
  //Singleton con UserSettings para acceder al peerid

  final settings = UserSettings();
  static final FileService _instancia = FileService._internal();
  factory FileService() => _instancia;

  FileService._internal();

  Future<String> getName() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd-HH-mm-ss");
    String fileDate = dateFormat.format(DateTime.now());

    //var filename = '${settings.peerId}$fileDate.mp4';
    var filename = '$fileDate.mp4';
    final directory = await getExternalStorageDirectory();
    var filepath = '${directory?.path}/$filename';
    log(filepath);
    return filepath;
  }

  // Future<String> uploadFile(String filename, String url) async {
  //   var msg = '';
  //   var request = http.MultipartRequest('POST', Uri.parse(url));
  //   request.files.add(await http.MultipartFile.fromPath('file', filename));
  //   try {
  //     var res = await request.send();
  //     msg = res.reasonPhrase == 'OK'
  //         ? '📥 Archivo recibido correctamente'
  //         : '😖 ERROR status code ' + res.statusCode.toString();
  //   } on Exception catch (e) {
  //     msg = e.toString();
  //   }
  //   return msg;
  // }

  // Future<String> onPressedUploadFile() async {
  //   // TODO: Selector de archivo? Y ciclo para varios?¿?¿
  //   var filepath = await getName();
  //   var res = '$filepath no existe';
  //   var uploadpath = settings.uploadUrl;
  //   if (await File(filepath).exists()) {
  //     File data = File(filepath);
  //     res = await uploadFile(data.path, uploadpath);
  //   } else {
  //     log(res);
  //   }
  //   return res;
  // }
}
