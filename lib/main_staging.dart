
import 'core/utils/enums.dart';
import 'flavor_config.dart';
import 'main.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  FlavorConfig.instantiate(
    flavor: Flavor.staging,
    baseUrl: "",
    appTitle: 'Smart Expense Tracker App',
  );
  await NearCartAppMain();
}