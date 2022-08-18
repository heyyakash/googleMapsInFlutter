// ignore_for_file: prefer_const_constructors, avoid_function_literals_in_foreach_calls, prefer_final_fields, sized_box_for_whitespace, unnecessary_string_interpolations

import 'dart:async';
import 'package:convert/convert.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import './ev_collections.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(
      MaterialApp(theme: ThemeData(primaryColor: Colors.black), home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final itemController = ItemScrollController();
  String activeId = '';
  String mapTheme = '';
  Completer<GoogleMapController> _controller = Completer();
  bool isMapCreated = false;
  static const sourceLocation = LatLng(12.9070513, 77.5675009);
  static String googleApiKey = "AIzaSyDjj1s1972Cg_pDtmWC5QGse4UMIcgWQUQ";
  static const _initialCameraPosition =
      CameraPosition(target: sourceLocation, zoom: 16);

  List<LatLng> polylineCoordinates = [];
  List<ChargingLocation> locations = [];
  Set<Marker> _markers = {
    Marker(markerId: MarkerId("source"), position: sourceLocation),
  };

  // Get Poly Points
  void getPolyPoints(desLat, desLng, id) async {
    polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult results = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey,
        PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
        PointLatLng(desLat, desLng));

    if (results.points.isNotEmpty) {
      results.points.forEach((point) {
        return polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
      final int index = locations.indexWhere((element) => element.id == id);
      setState(() {
        activeId = id;
        itemController.scrollTo(
            index: index, duration: Duration(milliseconds: 500));
      });
    }
  }

  // Get Locations
  void getLocations() async {
    String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=12.9070513%2C77.5675009&radius=30000&keyword=electric%2Cvehicle%2Ccharging&key=AIzaSyDjj1s1972Cg_pDtmWC5QGse4UMIcgWQUQ";
    var response = await http.get(Uri.parse(url));
    var data = await jsonDecode(response.body);
    data['results'].forEach((element) {
      ChargingLocation data = ChargingLocation(
          lat: double.parse(element['geometry']['location']['lat'].toString()),
          lng: double.parse(element['geometry']['location']['lng'].toString()),
          name: element['name'],
          id: element['place_id'],
          open: true,
          vicinity: element["vicinity"]);
      locations.add(data);
    });

    locations.forEach((element) {
      _markers.add(Marker(
          markerId: MarkerId(element.id),
          position: LatLng(element.lat, element.lng),
          onTap: () {
            getPolyPoints(element.lat, element.lng, element.id);
          },
          infoWindow: InfoWindow(
              title: element.name,
              snippet: element.vicinity
                  .replaceRange(20, element.vicinity.length, '...')),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)));
    });
  }

  // void scrollToIndex(int index) {
  //   itemController.jumpTo(
  //     index: index,
  //   );
  //   print("Required scroll $index");
  // }

  @override
  void initState() {
    super.initState();
    DefaultAssetBundle.of(context).loadString('assets/dark.json').then((value) {
      mapTheme = value;
    });
    getLocations();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return (Scaffold(
        body: Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          initialCameraPosition: _initialCameraPosition,
          onMapCreated: (GoogleMapController controller) {
            controller.setMapStyle(mapTheme);
            // _controller.complete(controller);
          },
          polylines: {
            Polyline(
                polylineId: PolylineId("route"),
                points: polylineCoordinates,
                color: Colors.blueAccent,
                width: 6)
          },
          markers: _markers,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 80, 0, 0),
          child: SizedBox(
            height: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                    child: ScrollablePositionedList.builder(
                  itemCount: locations.isNotEmpty ? locations.length : 0,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return StationBox(
                        setRoute: getPolyPoints,
                        lat: locations[index].lat,
                        currentIndex: index,
                        lng: locations[index].lng,
                        id: locations[index].id,
                        name: locations[index].name,
                        vicinity: locations[index].vicinity,
                        open: locations[index].open,
                        activeId: activeId);
                  },
                  itemScrollController: itemController,
                  scrollDirection: Axis.horizontal,
                  // children: locations.isNotEmpty
                  //     ? locations
                  //         .map((station) => StationBox(
                  //             setRoute: getPolyPoints,
                  //             lat: station.lat,
                  //             lng: station.lng,
                  //             id: station.id,
                  //             name: station.name,
                  //             vicinity: station.vicinity,
                  //             open: station.open,
                  //             activeId: activeId))
                  //         .toList()
                  //     : [Text("No Locations")],
                ))
              ],
            ),
          ),
        )
      ],
    )));
  }
}

class StationBox extends StatefulWidget {
  String name;
  // ignore: prefer_typing_uninitialized_variables
  final setRoute;
  // ignore: prefer_typing_uninitialized_variables
  // final setScroll;
  String vicinity;
  int currentIndex;
  String id;
  bool open;
  double lat;
  double lng;
  String activeId;
  StationBox(
      {Key? key,
      // required this.setScroll,
      required this.currentIndex,
      required this.setRoute,
      required this.lat,
      required this.lng,
      required this.id,
      required this.activeId,
      required this.name,
      required this.vicinity,
      required this.open})
      : super(key: key);

  @override
  State<StationBox> createState() => _StationBoxState();
}

class _StationBoxState extends State<StationBox> {
  late bool inUse;
  @override
  Widget build(BuildContext context) {
    if (widget.activeId == widget.id) {
      inUse = true;
      // widget.setScroll(widget.currentIndex);
    } else {
      inUse = false;
    }
    return InkWell(
      onTap: () {
        if (!inUse) {
          inUse = true;
          widget.setRoute(widget.lat, widget.lng, widget.id);
          setState(() {});
        } else {
          inUse = false;
          setState(() {});
        }
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 8.0, 0),
        height: 100,
        width: 300,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                // ignore: prefer_const_literals_to_create_immutables
                colors: inUse
                    ? [Colors.white, Colors.white]
                    : [
                        Color.fromARGB(255, 5, 42, 72),
                        Color.fromARGB(255, 8, 38, 89)
                      ]),
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // ignore: prefer_const_literals_to_create_immutables
                  children: [
                    Text(
                      "${widget.name}",
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: inUse ? Colors.blue : Colors.white),
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      maxLines: 1,
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      "${widget.vicinity}",
                      style: TextStyle(
                          fontSize: 14,
                          color: inUse ? Colors.blue : Colors.white),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Image.asset('assets/charging-station.png')
            ],
          ),
        ),
      ),
    );
  }
}

// Widget Boxes(String name, String vicinity, bool open) => Container(
//       margin: EdgeInsets.fromLTRB(0, 0, 8.0, 0),
//       height: 100,
//       width: 300,
//       decoration: BoxDecoration(
//           gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               // ignore: prefer_const_literals_to_create_immutables
//               colors: [
//                 Color.fromARGB(255, 5, 42, 72),
//                 Color.fromARGB(255, 8, 38, 89)
//               ]),
//           borderRadius: BorderRadius.circular(10)),
//       child: Padding(
//         padding: EdgeInsets.all(20),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Container(
//               width: 180,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 // ignore: prefer_const_literals_to_create_immutables
//                 children: [
//                   Text(
//                     "$name",
//                     style: TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white),
//                     overflow: TextOverflow.fade,
//                     softWrap: false,
//                     maxLines: 1,
//                   ),
//                   SizedBox(
//                     height: 5,
//                   ),
//                   Text(
//                     "$vicinity",
//                     style: TextStyle(
//                         fontSize: 14,
//                         color: Color.fromARGB(255, 214, 214, 214)),
//                     maxLines: 2,
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(
//               width: 10,
//             ),
//             Image.asset('assets/charging-station.png')
//           ],
//         ),
//       ),
//     );
