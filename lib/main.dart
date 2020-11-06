import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:salt_app/pages/upload.dart';
import 'package:salt_app/pages/send.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'package:salt_app/db/database_service.dart';

void main() => runApp(MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => SaltAppHome(),
        '/upload': (context) => ImageUpload(),
        '/send': (context) => Send(),
      },
    ));

class SaltAppHome extends StatefulWidget {
  @override
  _SaltAppHomeState createState() => _SaltAppHomeState();
}

class _SaltAppHomeState extends State<SaltAppHome> with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  int successfulSyncs = 0;
  int failedSyncs = 0;
  String result;
  bool loading = false;
  bool pending;
  List arr = [];
  String driverId;
  String driverName;
  int machineId = 0;
  File uploadLicense; //variable for choosed file
  File uploadPlate; //variable for choosed file
  String licenseBaseImage;
  String plateBaseImage;
  final picker = ImagePicker();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  void showAlertDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sync Completed'),
          content: SingleChildScrollView(
            child: Text('$successfulSyncs transaction(s) synced.'),
          ),
          actions: <Widget>[
            MaterialButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              height: 40,
              minWidth: 100,
              color: Theme.of(context).primaryColor,
              child: Text('Got it.',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
              onPressed: () {
                Navigator.of(context).pop();
                successfulSyncs = 0;
              },
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Something went wrong'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                    'There was an error sending the data, what do you want to do?'),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MaterialButton(
                      shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(5.0)),
                      height: 40,
                      minWidth: 100,
                      color: Theme.of(context).primaryColor,
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    MaterialButton(
                      shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(5.0)),
                      height: 40,
                      minWidth: 100,
                      color: Theme.of(context).primaryColor,
                      child: Text('Retry',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        syncTransactions();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  syncTransactions() async {
    controller.repeat();
    setState(() {
      loading = true;
    });
    // query all
    DatabaseHelper helper = DatabaseHelper.instance;
    int syncState = 0;
    final transactions = await helper.queryAllTransactions(syncState);
    if (transactions != null) {
      print('Transactions to sync: ${transactions.length}');
      transactions.forEach((transaction) async {
        print(
            'row ${transaction.id}: ${transaction.driver_id} ${transaction.transaction_timestamp}');
        String uploadurl = "http://midland.salt.jmmago.com/postData.php";
        try {
          var response = await http.post(uploadurl, body: {
            'driver_id': transaction.driver_id,
            'transaction_id': transaction.transaction_id,
            'transaction_timestamp': transaction.transaction_timestamp,
            'driver_name': transaction.driver_name,
            'machine_id': transaction.machine_id,
            'full_bucket_quantity': transaction.full_bucket_quantity,
            'five_gal_quantity': transaction.five_gal_quantity,
            'salt_type': transaction.salt_type,
            'driver_license': transaction.driver_license,
            'driver_plate': transaction.driver_plate
          });
          if (response.statusCode == 200) {
            var jsondata = json.decode(response.body); //decode json data
            if (jsondata["error"]) {
              //check error sent from server
              print(jsondata["msg"]);
              //if error return from server, show message from server
            } else {
              print("Upload successful");
              setState(() {
                successfulSyncs++;
              });
              if (successfulSyncs == transactions.length) {
                _update(transactions);
              }
            }
          } else {
            print("Error during connection to server");
            //there is error during connecting to server,
            //status code might be 404 = url not found
            setState(() {
              failedSyncs++;
            });
            if (failedSyncs == transactions.length) {
              setState(() {
                loading = false;
              });
              controller.stop();
              controller.reset();
              showErrorDialog();
              failedSyncs = 0;
            }
          }
        } catch (e) {
          print("Error processing data");
          print(e);
          //there is error during converting file image to base64 encoding.
          setState(() {
            failedSyncs++;
          });
          if (failedSyncs == transactions.length) {
            setState(() {
              loading = false;
            });
            controller.stop();
            controller.reset();
            showErrorDialog();
            failedSyncs = 0;
          }
        }
      });
    } else {
      print('No transactions to sync');
      setState(() {
        loading = false;
      });
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('No transactions to sync'),
        duration: Duration(seconds: 3),
      ));
    }
  }

  _update(transactions) async {
    if (transactions != null) {
      transactions.forEach((transaction) async {
        Transaction updateTransaction = Transaction();
        updateTransaction.driver_id = transaction.driver_id;
        updateTransaction.transaction_id = transaction.transaction_id;
        updateTransaction.transaction_timestamp =
            transaction.transaction_timestamp;
        updateTransaction.driver_name = transaction.driver_name;
        updateTransaction.machine_id = transaction.machine_id;
        updateTransaction.full_bucket_quantity =
            transaction.full_bucket_quantity;
        updateTransaction.five_gal_quantity = transaction.five_gal_quantity;
        updateTransaction.salt_type = transaction.salt_type;
        updateTransaction.driver_license = transaction.driver_license;
        updateTransaction.driver_plate = transaction.driver_plate;
        updateTransaction.transaction_synced = 1;
        final helper = DatabaseHelper.instance;
        int count = await helper.update(updateTransaction);
        print('updated $count row(s)');
        setState(() {
          loading = false;
          pending = false;
        });
      });
      controller.stop();
      controller.reset();
      showAlertDialog();
    }
  }

  void reset() {
    setState(() {
      uploadLicense = null;
      uploadPlate = null;
    });
  }

  Future<void> chooseLicense() async {
    var choosedimage = await picker.getImage(source: ImageSource.camera, maxHeight: 480, maxWidth: 640);
    //set source: ImageSource.camera to get image from camera
    setState(() {
      uploadLicense = File(choosedimage.path);
    });
  }

  Future<void> choosePlate() async {
    var choosedimage = await picker.getImage(source: ImageSource.camera, maxHeight: 480, maxWidth: 640);
    //set source: ImageSource.camera to get image from camera
    setState(() {
      uploadPlate = File(choosedimage.path);
    });
  }

  void push() {
    if (uploadLicense != null && uploadPlate != null) {
      List<int> licenseImageBytes = uploadLicense.readAsBytesSync();
      List<int> plateImageBytes = uploadPlate.readAsBytesSync();
      licenseBaseImage = base64Encode(licenseImageBytes);
      plateBaseImage = base64Encode(plateImageBytes);
      Navigator.pushNamed(context, '/upload', arguments: {
        'driverId': null,
        'licenseImg': this.uploadLicense,
        'plateImg': this.uploadPlate,
        'machineId': this.machineId,
        'license64': this.licenseBaseImage,
        'plate64': this.plateBaseImage,
      });
    } else if (driverId != null && driverName != null) {
      Navigator.pushNamed(context, '/upload', arguments: {
        'driverId': this.driverId,
        'driverName': this.driverName,
        'machineId': this.machineId,
      });
    }
  }

  @override
  initState() {
    checkFirstRun();
    checkSyncState();
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat();
    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.linear,
    );
    controller.stop();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  checkFirstRun() async {
    SharedPreferences prefs = await _prefs;
    var isFirstTime = prefs.getBool('first_time');
    if (isFirstTime != null && !isFirstTime) {
      setState(() {
        machineId = prefs.getInt('machineId') ?? 0;
      });
      print('Broken');
    } else {
      prefs.setBool('first_time', false);
      machineId = Random().nextInt(pow(2, 31));
      prefs.setInt('machineId', machineId);
      print('Virgin');
    }
  }

  checkSyncState() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    int syncState = 0;
    final transactions = await helper.queryAllTransactions(syncState);
    if (transactions != null) {
      transactions.forEach((transaction) {
        print('row ${transaction.id}');
        setState(() {
          pending = true;
        });
      });
    } else {
      print('No transactions to be synced.');
      setState(() {
        pending = false;
      });
    }
  }

  Future _scanQR() async {
    try {
      ScanResult qrResult = await BarcodeScanner.scan();
      result = qrResult.rawContent.toString();
      if (result != '') {
        setState(() {
          arr = result.split('-');
          driverId = arr[0];
          driverName = arr[1];
        });
      }
      print(arr);
      push();
    } catch (e) {
      print('Error: $result');
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          toolbarHeight: 80.0,
          backgroundColor: Colors.white,
          title: Padding(
              padding: EdgeInsets.all(10.0),
              child: Image.asset(
                "assets/images/logo.png",
                height: 25.0,
              )),
          actions: <Widget>[
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Row(
                children: <Widget>[
                  FlatButton(
                      shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(100)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      onPressed: () {
                        if (loading == false) {
                          syncTransactions();
                        }
                      },
                      color: Colors.grey[300],
                      child: Row(
                        children: <Widget>[
                          Text("Sync",
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 18)),
                          SizedBox(width: 18),
                          RotationTransition(
                            turns: animation,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(pi),
                              child: Icon(Icons.sync,
                                  color:
                                      pending == true ? Colors.red : Colors.green,
                                  size: 30),
                            ),
                          ),
                        ],
                      ))
                ],
              ),
            )
          ],
        ),
        body: loading
            ? Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        children: [
                          if (uploadLicense == null && uploadPlate == null)
                            Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 20, 10, 0),
                                  child: Container(
                                      decoration: BoxDecoration(boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey,
                                            blurRadius: 10,
                                            offset: Offset(0, 3))
                                      ]),
                                      child: FlatButton(
                                          shape: new RoundedRectangleBorder(
                                              borderRadius:
                                                  new BorderRadius.circular(
                                                      10.0)),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 15),
                                          onPressed: _scanQR,
                                          color: Colors.blue[500],
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Image.asset(
                                                'assets/images/scan.png',
                                                height: 30,
                                              ),
                                              SizedBox(width: 20),
                                              Text("Scan",
                                                  style: TextStyle(
                                                      fontSize: 30,
                                                      color: Colors.white)),
                                            ],
                                          ))),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 50),
                                  child: Text(
                                    "or capture",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 20),
                                  ),
                                ),
                              ],
                            ),
                          if (uploadLicense != null || uploadPlate != null)
                            SizedBox(height: 20),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: Container(
                                  decoration: BoxDecoration(boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey[400],
                                        blurRadius: 10,
                                        offset: Offset(0, 3))
                                  ]),
                                  child: FlatButton(
                                      shape: new RoundedRectangleBorder(
                                          borderRadius:
                                              new BorderRadius.circular(10.0)),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 15),
                                      onPressed: chooseLicense,
                                      color: Colors.white,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Image.asset(
                                            'assets/images/license.png',
                                            height: 35,
                                          ),
                                          SizedBox(width: 20),
                                          Text("Driving License",
                                              style: TextStyle(
                                                  fontSize: 25,
                                                  color: Colors.grey)),
                                        ],
                                      )),
                                ),
                              )
                            ],
                          ),
                          SizedBox(height: 20),
                          if (uploadLicense != null)
                          Container(
                                      //else show image here
                                      child: SizedBox(
                                          height: 150,
                                          child: Image.file(
                                              uploadLicense) //load image from file
                                          )),
                          uploadLicense == null
                              ? SizedBox(height: 60)
                              : SizedBox(height: 20),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: Container(
                                  decoration: BoxDecoration(boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey[400],
                                        blurRadius: 10,
                                        offset: Offset(0, 3))
                                  ]),
                                  child: FlatButton(
                                      shape: new RoundedRectangleBorder(
                                          borderRadius:
                                              new BorderRadius.circular(10.0)),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 15),
                                      onPressed: choosePlate,
                                      color: Colors.white,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Image.asset(
                                            'assets/images/plate.png',
                                            height: 35,
                                          ),
                                          SizedBox(width: 20),
                                          Text("License Plate",
                                              style: TextStyle(
                                                  fontSize: 25,
                                                  color: Colors.grey)),
                                        ],
                                      )),
                                ),
                              )
                            ],
                          ),
                          SizedBox(height: 20),
                          if (uploadPlate != null)
                          Container(
                                      //else show image here
                                      child: SizedBox(
                                          height: 150,
                                          child: Image.file(
                                              uploadPlate) //load image from file
                                          )),
                          SizedBox(height: 20)
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                if (uploadLicense != null || uploadPlate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: MaterialButton(
                      shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(5.0)),
                      height: 50,
                      minWidth: 100,
                      color: Theme.of(context).primaryColor,
                      child: Text(
                        'Reset',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      onPressed: () => reset(),
                    ),
                  ),
                if (uploadPlate != null && uploadLicense != null)
                  MaterialButton(
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(5.0)),
                    height: 50,
                    minWidth: 100,
                    color: Theme.of(context).primaryColor,
                    child: Text(
                      'Next',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    onPressed: () => push(),
                  ),
              ],
            ),
          ),
        ));
  }
}
