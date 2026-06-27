import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/printer_repository.dart';
import 'printer_event.dart';
import 'printer_state.dart';

class PrinterBloc extends Bloc<PrinterEvent, PrinterState> {
  final PrinterRepository repository;

  PrinterBloc({required this.repository}) : super(const PrinterState()) {
    on<InitPrinterEvent>(_onInit);
    on<RefreshPrinterEvent>(_onRefresh);
    on<ScanPrintersEvent>(_onScan);
    on<ConnectPrinterEvent>(_onConnect);
    on<DisconnectPrinterEvent>(_onDisconnect);
    on<TestPrintEvent>(_onTestPrint);
  }

  void _onInit(InitPrinterEvent event, Emitter<PrinterState> emit) {
    final mac = repository.getSavedPrinterMac();
    final name = repository.getSavedPrinterName();
    emit(state.copyWith(
      status: PrinterStatus.initial,
      connectedMac: mac,
      connectedName: name,
    ));
  }

  Future<void> _onRefresh(
      RefreshPrinterEvent event, Emitter<PrinterState> emit) async {
    emit(state.copyWith(status: PrinterStatus.scanning, clearError: true));
    try {
      final devices = await repository.scanDevices();
      if (devices.isEmpty) {
        emit(state.copyWith(
          status: PrinterStatus.scanFailure,
          errorMessage: 'No paired Bluetooth devices found.',
          devices: [],
        ));
        return;
      }

      // Only attempt to reconnect to the previously saved printer, not every
      // paired device. Connecting to an arbitrary device (speaker, phone, etc.)
      // could leak receipt data to unintended recipients.
      final savedMac = state.connectedMac ?? repository.getSavedPrinterMac();
      if (savedMac == null) {
        emit(state.copyWith(
          status: PrinterStatus.scanFailure,
          errorMessage: 'No printer saved. Tap a device below to connect.',
          devices: devices,
        ));
        return;
      }

      final savedDevice = devices.where((d) => d.macAdress == savedMac).firstOrNull;
      if (savedDevice == null) {
        emit(state.copyWith(
          status: PrinterStatus.scanFailure,
          errorMessage: 'Saved printer not found among paired devices.',
          devices: devices,
        ));
        return;
      }

      final success = await repository.connect(savedDevice.macAdress);
      if (success) {
        await repository.savePrinterData(savedDevice.macAdress, savedDevice.name);
        emit(state.copyWith(
          status: PrinterStatus.connected,
          connectedMac: savedDevice.macAdress,
          connectedName: savedDevice.name,
          devices: devices,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: PrinterStatus.scanFailure,
          errorMessage: 'Could not reconnect to ${savedDevice.name}.',
          devices: devices,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: PrinterStatus.scanFailure,
        errorMessage: 'Scan failed. Check Bluetooth permissions.',
      ));
    }
  }

  Future<void> _onScan(
      ScanPrintersEvent event, Emitter<PrinterState> emit) async {
    emit(state.copyWith(status: PrinterStatus.scanning, clearError: true));
    try {
      final devices = await repository.scanDevices();
      emit(state.copyWith(
        status: PrinterStatus.scanSuccess,
        devices: devices,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PrinterStatus.scanFailure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onConnect(
      ConnectPrinterEvent event, Emitter<PrinterState> emit) async {
    emit(state.copyWith(status: PrinterStatus.connecting, clearError: true));
    final success = await repository.connect(event.mac);
    if (success) {
      await repository.savePrinterData(event.mac, event.name);
      emit(state.copyWith(
        status: PrinterStatus.connected,
        connectedMac: event.mac,
        connectedName: event.name,
      ));
    } else {
      emit(state.copyWith(
        status: PrinterStatus.connectionFailure,
        errorMessage: 'Failed to connect to printer',
      ));
    }
  }

  Future<void> _onDisconnect(
      DisconnectPrinterEvent event, Emitter<PrinterState> emit) async {
    await repository.disconnect();
    await repository.clearPrinterData();
    emit(PrinterState(
      status: PrinterStatus.disconnected,
      devices: state.devices,
    ));
  }

  Future<void> _onTestPrint(
      TestPrintEvent event, Emitter<PrinterState> emit) async {
    emit(state.copyWith(status: PrinterStatus.testPrinting));
    try {
      await repository.testPrint(event.shopName);
      emit(state.copyWith(status: PrinterStatus.connected));
    } catch (e) {
      emit(state.copyWith(
        status: PrinterStatus.scanFailure,
        errorMessage: 'Test print failed. Check printer connection.',
      ));
    }
  }
}
