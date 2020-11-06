import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:salt_app/db/database_service.dart';

class Send extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SendState();
  }
}

class _SendState extends State<Send> {
  bool loading = false;
  String driverId = 'No ID due to QR selection';
  String driverLicense = 'QR selected';
  String driverPlate = 'QR selected';
  Map data = {};

  void cleanScreen() {
    // ignore: unused_local_variable
    File uploadLicense; //variable for choosed file
    // ignore: unused_local_variable
    File uploadPlate; //variable for choosed file
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Salt App says:'),
          content: SingleChildScrollView(
            child: Text('Data sent Successfully.'),
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
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/', (Route<dynamic> route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> send() async {
    setState(() {
      loading = true;
    });
    //show your own loading or progressing code here
    String uploadurl = "http://midland.salt.jmmago.com/postData.php";
    try {
      DateTime date = DateTime.now();
      var response = await http.post(uploadurl, body: {
        'driver_id': data['driverId'] != null ? data['driverId'] : driverId,
        'transaction_id': date.millisecondsSinceEpoch.toString(),
        'transaction_timestamp': date.toString(),
        'driver_name':
            data['driverId'] != null ? data['qrName'] : data['inputName'],
        'machine_id': data['machineId'].toString(),
        'full_bucket_quantity': data['fbQuantity'].toString(),
        'five_gal_quantity': data['fgQuantity'].toString(),
        'salt_type': data['saltType'].toString(),
        'driver_license':
            data['driverId'] != null ? driverLicense : data['license64'],
        'driver_plate': data['driverId'] != null ? driverPlate : data['plate64']
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
            loading = false;
          });
          showSuccessDialog();
        }
      } else {
        print("Error during connection to server");
        //there is error during connecting to server,
        //status code might be 404 = url not found
        setState(() {
          loading = false;
        });
        showErrorDialog();
      }
    } catch (e) {
      print("Error processing data");
      print(e);
      setState(() {
        loading = false;
      });
      //there is error during converting file image to base64 encoding.
      showErrorDialog();
    }
  }

  save() async {
    // insert
    DateTime date = DateTime.now();
    Transaction transaction = Transaction();
    transaction.driver_id =
        data['driverId'] != null ? data['driverId'] : driverId;
    transaction.transaction_id = date.millisecondsSinceEpoch.toString();
    transaction.transaction_timestamp = date.toString();
    transaction.driver_name =
        data['driverId'] != null ? data['qrName'] : data['inputName'];
    transaction.machine_id = data['machineId'].toString();
    transaction.full_bucket_quantity = data['fbQuantity'].toString();
    transaction.five_gal_quantity = data['fgQuantity'].toString();
    transaction.salt_type = data['saltType'].toString();
    transaction.driver_license =
        data['driverId'] != null ? driverLicense : data['license64'];
    transaction.driver_plate =
        data['driverId'] != null ? driverPlate : data['plate64'];
    transaction.transaction_synced = 0;
    DatabaseHelper helper = DatabaseHelper.instance;
    int id = await helper.insert(transaction);
    print('inserted row: $id');
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
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
                      child: Text('Sync later',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        save();
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
                        send();
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

  @override
  Widget build(BuildContext context) {
    data = ModalRoute.of(context).settings.arguments;
    print(data);
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(color: Colors.cyan),
          backgroundColor: Colors.white,
          title: Text("Resume", style: TextStyle(color: Colors.cyan)),
        ),
        body: loading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (data['driverId'] != null)
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (data['driverId'] != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.cyan[200],
                                    borderRadius: BorderRadius.circular(50)),
                                child: Text('Driver ID: ' + data['driverId']),
                              ),
                            if (data['driverId'] != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.cyan[200],
                                    borderRadius: BorderRadius.circular(50)),
                                child: Text('Hi, ' + data['qrName']),
                              )
                          ],
                        ),
                      ),
                      data['inputName'] != ''
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('Company Driver:'))
                          : Container(),
                      if (data['driverId'] == null)
                      SizedBox(height: 10),
                      data['inputName'] != ''
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(data['inputName'],
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold)))
                          : Container(),
                      data['inputName'] != ''
                          ? Divider(
                              height: 20,
                              indent: 20,
                              endIndent: 20,
                              color: Colors.grey[500],
                            )
                          : Container(),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('Salt Type:')),
                      SizedBox(height: 10),
                      data['saltType'] == 1
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('Normal',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold)))
                          : Container(),
                      data['saltType'] == 2
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('Treated',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold)))
                          : Container(),
                      data['saltType'] == 3
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('Mix',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold)))
                          : Container(),
                      Divider(
                        height: 20,
                        indent: 20,
                        endIndent: 20,
                        color: Colors.grey[500],
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('Transport type:')),
                      SizedBox(height: 10),
                      data['transportType'] == 1
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('Full Bucket',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold)))
                          : Container(),
                      data['transportType'] == 2
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('5 Gallon',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold)))
                          : Container(),
                      Divider(
                        height: 20,
                        indent: 20,
                        endIndent: 20,
                        color: Colors.grey[500],
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('Salt Quantity:')),
                      SizedBox(height: 10),
                      data['fbQuantity'] != 0
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(data['fbQuantity'].toString(),
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold)))
                          : Container(),
                      data['fgQuantity'] != 0
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(data['fgQuantity'].toString(),
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold)))
                          : Container(),
                      Divider(
                        height: 20,
                        indent: 20,
                        endIndent: 20,
                        color: Colors.grey[500],
                      ),
                      if (data['licenseImg'] != null &&
                          data['plateImg'] != null)
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('License & Plate:')),
                      SizedBox(height: 10),
                      data['licenseImg'] != null && data['plateImg'] != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.file(data['licenseImg'], height: 150),
                                SizedBox(width: 10),
                                Image.file(data['plateImg'], height: 150)
                              ],
                            )
                          : Container()
                    ]),
              ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                MaterialButton(
                  height: 50,
                  minWidth: 100,
                  color: loading == true ? Colors.grey : Theme.of(context).primaryColor,
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  onPressed: () {
                    if (loading == false) {
                      save();
                    }
                  },
                ),
                MaterialButton(
                  height: 50,
                  minWidth: 100,
                  color: loading == true ? Colors.grey : Theme.of(context).primaryColor,
                  child: Text(
                    'Send',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  onPressed: () {
                    if (loading == false) {
                      send();
                    }
                  },
                )
              ],
            ),
          ),
        ));
  }
}
