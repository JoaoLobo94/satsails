import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:satsails/models/bitcoin_config_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satsails/providers/auth_provider.dart';

final bitcoinConfigProvider = FutureProvider<BitcoinConfig>((ref) async {
  final authModel = ref.read(authModelProvider);
  final mnemonic = await authModel.getMnemonic();
  if (mnemonic == null || mnemonic.isEmpty) {
    throw Exception('Mnemonic is null or empty');
  }
  return BitcoinConfig(
    mnemonic: mnemonic,
    network: Network.bitcoin,
    externalKeychain: KeychainKind.externalChain,
    internalKeychain: KeychainKind.internalChain,
    isElectrumBlockchain: true,
  );
});

final createInternalDescriptorProvider = FutureProvider<Descriptor>((ref) {
  return ref.watch(bitcoinConfigProvider.future).then((config) {
    BitcoinConfigModel bitcoinConfigModel = BitcoinConfigModel(config);
    return bitcoinConfigModel.createInternalDescriptor();
  });
});

final createExternalDescriptorProvider = FutureProvider<Descriptor>((ref) {
  return ref.watch(bitcoinConfigProvider.future).then((config) {
    BitcoinConfigModel bitcoinConfigModel = BitcoinConfigModel(config);
    return bitcoinConfigModel.createExternalDescriptor();
  });
});

final initializeBlockchainProvider = FutureProvider<Blockchain>((ref) {
  return ref.watch(bitcoinConfigProvider.future).then((config) {
    BitcoinConfigModel bitcoinConfigModel = BitcoinConfigModel(config);
    return bitcoinConfigModel.initializeBlockchain();
  });
});

final restoreWalletProvider = FutureProvider<Wallet>((ref) {
  return ref.watch(bitcoinConfigProvider.future).then((config) async {
    final externalDescriptor = await ref.watch(createExternalDescriptorProvider.future);
    final internalDescriptor = await ref.watch(createInternalDescriptorProvider.future);
    BitcoinConfigModel bitcoinConfigModel = BitcoinConfigModel(config);
    return bitcoinConfigModel.restoreWallet(externalDescriptor, internalDescriptor);
  });
});