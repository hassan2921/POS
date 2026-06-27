import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/cart_item.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/usecases/product_usecases.dart';
import 'package:billing_app/features/sales/domain/entities/sale.dart';
import 'package:billing_app/features/sales/domain/entities/sale_item.dart';
import 'package:billing_app/features/sales/domain/usecases/sale_usecases.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../../../core/data/hive_database.dart';

part 'billing_event.dart';
part 'billing_state.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final GetProductByBarcodeUseCase getProductByBarcodeUseCase;
  final UpdateProductUseCase updateProductUseCase;
  final SaveSaleUseCase saveSaleUseCase;

  static const int _maxCartItems = 50;

  BillingBloc({
    required this.getProductByBarcodeUseCase,
    required this.updateProductUseCase,
    required this.saveSaleUseCase,
  }) : super(const BillingState()) {
    on<ScanBarcodeEvent>(_onScanBarcode);
    on<AddProductToCartEvent>(_onAddProductToCart);
    on<AddManualItemEvent>(_onAddManualItem);
    on<RemoveProductFromCartEvent>(_onRemoveProductFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<ConfirmOrderEvent>(_onConfirmOrder);
    on<PrintReceiptEvent>(_onPrintReceipt);
    on<ClearErrorEvent>((event, emit) => emit(state.copyWith(clearError: true)));
  }

  Future<void> _onScanBarcode(
      ScanBarcodeEvent event, Emitter<BillingState> emit) async {
    final result = await getProductByBarcodeUseCase(event.barcode);
    result.fold(
      (failure) =>
          emit(state.copyWith(error: 'Product not found: ${event.barcode}')),
      (product) {
        emit(state.copyWith(clearError: true));
        add(AddProductToCartEvent(product));
      },
    );
  }

  void _onAddManualItem(
      AddManualItemEvent event, Emitter<BillingState> emit) {
    if (state.cartItems.length >= _maxCartItems) {
      emit(state.copyWith(error: 'Cart is full (max $_maxCartItems items)'));
      return;
    }
    final manualId = 'MANUAL-${const Uuid().v4()}';
    final product = Product(
      id: manualId,
      name: event.name.trim(),
      barcode: manualId,
      price: event.price,
      stock: 0,
    );
    final items = [
      ...state.cartItems,
      CartItem(product: product, quantity: event.quantity),
    ];
    emit(state.copyWith(cartItems: items, clearError: true));
  }

  void _onAddProductToCart(
      AddProductToCartEvent event, Emitter<BillingState> emit) {
    final cleanState = state.copyWith(error: null);
    final existingIndex = cleanState.cartItems
        .indexWhere((item) => item.product.id == event.product.id);

    if (existingIndex >= 0) {
      final existingItem = cleanState.cartItems[existingIndex];
      final newQuantity = existingItem.quantity + 1;

      if (event.product.stock > 0 && newQuantity > event.product.stock) {
        emit(cleanState.copyWith(
            error:
                '${event.product.name}: only ${event.product.stock} in stock'));
        return;
      }

      final items = List<CartItem>.from(cleanState.cartItems);
      items[existingIndex] = existingItem.copyWith(quantity: newQuantity);
      emit(cleanState.copyWith(cartItems: items, error: null));
    } else {
      if (cleanState.cartItems.length >= _maxCartItems) {
        emit(cleanState.copyWith(
            error: 'Cart is full (max $_maxCartItems items)'));
        return;
      }
      if (event.product.stock <= 0) {
        emit(cleanState.copyWith(
            error: '${event.product.name} is out of stock'));
        return;
      }

      emit(cleanState.copyWith(cartItems: [
        ...cleanState.cartItems,
        CartItem(product: event.product)
      ], error: null));
    }
  }

  void _onRemoveProductFromCart(
      RemoveProductFromCartEvent event, Emitter<BillingState> emit) {
    final updatedList = state.cartItems
        .where((item) => item.product.id != event.productId)
        .toList();
    emit(state.copyWith(cartItems: updatedList));
  }

  void _onUpdateQuantity(
      UpdateQuantityEvent event, Emitter<BillingState> emit) {
    if (event.quantity <= 0) {
      add(RemoveProductFromCartEvent(event.productId));
      return;
    }
    final index = state.cartItems
        .indexWhere((item) => item.product.id == event.productId);
    if (index >= 0) {
      final product = state.cartItems[index].product;

      if (product.stock > 0 && event.quantity > product.stock) {
        emit(state.copyWith(
            error: '${product.name}: only ${product.stock} in stock'));
        return;
      }

      final items = List<CartItem>.from(state.cartItems);
      items[index] = items[index].copyWith(quantity: event.quantity);
      emit(state.copyWith(cartItems: items));
    }
  }

  void _onClearCart(ClearCartEvent event, Emitter<BillingState> emit) {
    emit(const BillingState());
  }

  Future<void> _onConfirmOrder(
      ConfirmOrderEvent event, Emitter<BillingState> emit) async {
    emit(state.copyWith(isConfirming: true, clearError: true));

    try {
      // Pre-confirm: re-fetch current stock levels for each real product
      final List<({CartItem cartItem, Product liveProduct})> stockChecked = [];
      for (final cartItem in state.cartItems) {
        final result =
            await getProductByBarcodeUseCase(cartItem.product.barcode);
        // Manual items (MANUAL- prefix) won't be found — use the cart product itself
        final liveProduct = result.getOrElse((_) => cartItem.product);

        if (liveProduct.stock > 0 &&
            cartItem.quantity > liveProduct.stock) {
          emit(state.copyWith(
            isConfirming: false,
            error:
                '${cartItem.product.name}: only ${liveProduct.stock} left in stock. Please adjust quantity.',
          ));
          return;
        }
        stockChecked.add((cartItem: cartItem, liveProduct: liveProduct));
      }

      // Deduct stock using freshly-fetched stock values (fixes TOCTOU gap)
      for (final entry in stockChecked) {
        final cartItem = entry.cartItem;
        final liveProduct = entry.liveProduct;

        // Skip manual items (stock == 0 means no stock tracking)
        if (liveProduct.stock == 0 &&
            cartItem.product.id.startsWith('MANUAL-')) {
          continue;
        }

        final updatedProduct = Product(
          id: liveProduct.id,
          name: liveProduct.name,
          barcode: liveProduct.barcode,
          price: liveProduct.price,
          stock: (liveProduct.stock - cartItem.quantity).clamp(0, 999999),
        );

        var updateFailed = false;
        final updateResult = await updateProductUseCase(updatedProduct);
        updateResult.fold(
          (failure) {
            emit(state.copyWith(
              isConfirming: false,
              error: 'Failed to update stock for ${updatedProduct.name}',
            ));
            updateFailed = true;
          },
          (_) {},
        );

        if (updateFailed) return;
      }

      // Save sale to local history
      final sale = Sale(
        id: const Uuid().v4(),
        date: DateTime.now(),
        items: state.cartItems
            .map((c) => SaleItem(
                  productId: c.product.id,
                  productName: c.product.name,
                  barcode: c.product.barcode,
                  quantity: c.quantity,
                  price: c.product.price,
                  total: c.total,
                ))
            .toList(),
        total: state.totalAmount,
        synced: false,
      );

      var saveFailed = false;
      final saveResult = await saveSaleUseCase(sale);
      saveResult.fold(
        (failure) {
          emit(state.copyWith(
            isConfirming: false,
            error: 'Failed to save sale record',
          ));
          saveFailed = true;
        },
        (_) {},
      );

      if (saveFailed) return;

      emit(state.copyWith(isConfirming: false, orderConfirmed: true));
    } catch (e) {
      emit(state.copyWith(
          isConfirming: false, error: 'Failed to confirm order. Please retry.'));
    }
  }

  Future<void> _onPrintReceipt(
      PrintReceiptEvent event, Emitter<BillingState> emit) async {
    final printerHelper = PrinterHelper();

    if (!printerHelper.isConnected) {
      final savedMac =
          HiveDatabase.settingsBox.get('printer_mac') as String?;
      if (savedMac != null) {
        final connected = await printerHelper.connect(savedMac);
        if (!connected) {
          // Emit error without immediately clearing — let SnackBar display
          emit(state.copyWith(error: 'Failed to auto-connect to printer'));
          return;
        }
      } else {
        emit(state.copyWith(
            error: 'Printer not connected. Go to Settings to pair a printer.'));
        return;
      }
    }

    emit(state.copyWith(
        isPrinting: true, printSuccess: false, clearError: true));

    try {
      final items = state.cartItems
          .map((item) => {
                'name': item.product.name,
                'qty': item.quantity,
                'price': item.product.price,
                'total': item.total,
              })
          .toList();

      await printerHelper.printReceipt(
        shopName: event.shopName,
        address1: event.address1,
        address2: event.address2,
        phone: event.phone,
        items: items,
        total: state.totalAmount,
        footer: event.footer,
      );

      emit(state.copyWith(isPrinting: false, printSuccess: true));
    } catch (e) {
      emit(state.copyWith(isPrinting: false, error: 'Print failed. Check printer connection.'));
    }
  }
}
