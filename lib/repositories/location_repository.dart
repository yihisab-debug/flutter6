import '../models/location_model.dart';

class LocationRepository {
  static const List<LocationModel> _locations = [
    LocationModel(
      id: 'almaty_center',
      name: 'Центр (пл. Республики)',
      latitude: 43.2389,
      longitude: 76.8897,
    ),
    LocationModel(
      id: 'almaty_airport',
      name: 'Аэропорт Алматы',
      latitude: 43.3521,
      longitude: 77.0405,
    ),
    LocationModel(
      id: 'almaty_train',
      name: 'Вокзал Алматы-2',
      latitude: 43.2806,
      longitude: 76.9402,
    ),
    LocationModel(
      id: 'almaty_mega',
      name: 'ТРЦ Mega Park',
      latitude: 43.2622,
      longitude: 76.9286,
    ),
    LocationModel(
      id: 'almaty_dostyk',
      name: 'Dostyk Plaza',
      latitude: 43.2230,
      longitude: 76.9559,
    ),
    LocationModel(
      id: 'almaty_medeu',
      name: 'Медеу',
      latitude: 43.1583,
      longitude: 77.0577,
    ),
    LocationModel(
      id: 'almaty_kokTobe',
      name: 'Кок-Тобе',
      latitude: 43.2308,
      longitude: 76.9744,
    ),
    LocationModel(
      id: 'almaty_satbayev',
      name: 'Satbayev University',
      latitude: 43.2389,
      longitude: 76.9292,
    ),
    LocationModel(
      id: 'almaty_kazgu',
      name: 'КазНУ им. аль-Фараби',
      latitude: 43.2167,
      longitude: 76.8865,
    ),
    LocationModel(
      id: 'almaty_esentai',
      name: 'Esentai Mall',
      latitude: 43.2196,
      longitude: 76.9317,
    ),
  ];

  List<LocationModel> getAll() => List.unmodifiable(_locations);

  LocationModel? findById(String id) {
    for (final l in _locations) {
      if (l.id == id) return l;
    }
    return null;
  }

  LocationModel? findByName(String name) {
    for (final l in _locations) {
      if (l.name == name) return l;
    }
    return null;
  }
}
