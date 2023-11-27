import 'package:xml/xml.dart';

/// [
///   {
///     "name": "GeForce RTX 3090",
///     "temp": 40,
///     "power": "30W / 350W",
///     "memory": {
///       "total": 24268,
///       "used": 240,
///       "unit": "MiB",
///       "processes": [
///         {
///           "pid": 1456,
///           "name": "/usr/lib/xorg/Xorg",
///           "memory": 40
///         },
///       ]
///     },
///   }
/// ]
///

class NvdiaSmi {
  static List<NvdiaSmiItem> fromXml(String raw) {
    final xmlData = XmlDocument.parse(raw);
    final gpus = xmlData.findAllElements('gpu');
    final result = List<NvdiaSmiItem?>.generate(gpus.length, (index) {
      final gpu = gpus.elementAt(index);
      final name = gpu.findElements('product_name').firstOrNull?.innerText;
      final temp = gpu
          .findElements('temperature')
          .firstOrNull
          ?.findElements('gpu_temp')
          .firstOrNull
          ?.innerText;
      final power = gpu.findElements('gpu_power_readings').firstOrNull;
      final powerDraw =
          power?.findElements('power_draw').firstOrNull?.innerText;
      final powerLimit =
          power?.findElements('current_power_limit').firstOrNull?.innerText;
      final memory = gpu.findElements('fb_memory_usage').firstOrNull;
      final memoryUsed = memory?.findElements('used').firstOrNull?.innerText;
      final memoryTotal = memory?.findElements('total').firstOrNull?.innerText;
      final processes = gpu
          .findElements('processes')
          .firstOrNull
          ?.findElements('process_info');
      final memoryProcesses =
          List<NvdiaSmiMemProcess?>.generate(processes?.length ?? 0, (index) {
        final process = processes?.elementAt(index);
        final pid = process?.findElements('pid').firstOrNull?.innerText;
        final name =
            process?.findElements('process_name').firstOrNull?.innerText;
        final memory =
            process?.findElements('used_memory').firstOrNull?.innerText;
        if (pid != null && name != null && memory != null) {
          return NvdiaSmiMemProcess(
            int.parse(pid),
            name,
            int.parse(
              memory.split(' ').firstOrNull ?? '0',
            ),
          );
        }
        return null;
      });
      memoryProcesses.removeWhere((element) => element == null);
      if (name != null &&
          temp != null &&
          powerDraw != null &&
          powerLimit != null &&
          memory != null) {
        return NvdiaSmiItem(
          name,
          int.parse(temp.split(' ').firstOrNull ?? '0'),
          '$powerDraw / $powerLimit',
          NvdiaSmiMem(
            int.parse(memoryTotal?.split(' ').firstOrNull ?? '0'),
            int.parse(memoryUsed?.split(' ').firstOrNull ?? '0'),
            'MiB',
            List.from(memoryProcesses),
          ),
        );
      }
      return null;
    });
    result.removeWhere((element) => element == null);
    return List.from(result);
  }
}

class NvdiaSmiItem {
  final String name;
  final int temp;
  final String power;
  final NvdiaSmiMem memory;

  const NvdiaSmiItem(this.name, this.temp, this.power, this.memory);

  @override
  String toString() {
    return 'NvdiaSmiItem{name: $name, temp: $temp, power: $power, memory: $memory}';
  }
}

class NvdiaSmiMem {
  final int total;
  final int used;
  final String unit;
  final List<NvdiaSmiMemProcess> processes;

  const NvdiaSmiMem(this.total, this.used, this.unit, this.processes);

  @override
  String toString() {
    return 'NvdiaSmiMem{total: $total, used: $used, unit: $unit, processes: $processes}';
  }
}

class NvdiaSmiMemProcess {
  final int pid;
  final String name;
  final int memory;

  const NvdiaSmiMemProcess(this.pid, this.name, this.memory);

  @override
  String toString() {
    return 'NvdiaSmiMemProcess{pid: $pid, name: $name, memory: $memory}';
  }
}
