
import 'core/utils/enums.dart';
import 'flavor_config.dart';
import 'main.dart';

void main() async {
  FlavorConfig.instantiate(
    flavor: Flavor.staging,
    baseUrl: "",
    appTitle: 'Smart Expense Tracker App',
  );
  await NearCartAppMain();
}