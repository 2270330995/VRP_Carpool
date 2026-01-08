import 'package:carpoolfrontend/models/driver.dart';
import 'package:carpoolfrontend/models/passenger.dart';
import 'package:carpoolfrontend/models/destination.dart';

class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  final List<Driver> drivers = [];
  final List<Passenger> passengers = [];
  Destination? destination;

  void addDriver(Driver driver) {
    drivers.add(driver);
  }

  void updateDriver(Driver driver) {
    final index = drivers.indexWhere((d) => d.id == driver.id);
    if (index != -1) {
      drivers[index] = driver;
    }
  }

  void deleteDriver(String id) {
    drivers.removeWhere((d) => d.id == id);
  }

  void addPassenger(Passenger passenger) {
    passengers.add(passenger);
  }

  void updatePassenger(Passenger passenger) {
    final index = passengers.indexWhere((p) => p.id == passenger.id);
    if (index != -1) {
      passengers[index] = passenger;
    }
  }

  void deletePassenger(String id) {
    passengers.removeWhere((p) => p.id == id);
  }

  void setDestination(Destination dest) {
    destination = dest;
  }
}
