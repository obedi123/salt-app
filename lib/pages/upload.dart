import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUpload extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ImageUpload();
  }
}

class _ImageUpload extends State<ImageUpload> {
  final driverName = TextEditingController();
  int saltType = 1;
  int transportType = 1;
  Map data = {};
  double fullBucketQuantity = 0;
  double fiveGalQuantity = 0;
  File uploadLicense; //variable for choosed file
  File uploadPlate; //variable for choosed file
  final picker = ImagePicker();

  FocusNode myFocusNode;

  @override
  void initState() {
    super.initState();

    myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    myFocusNode.dispose();
    driverName.dispose();
    super.dispose();
  }

  void reset() {
    if (fullBucketQuantity != 0) {
      setState(() {
        fullBucketQuantity = 0;
      });
    }
    if (fiveGalQuantity != 0) {
      setState(() {
        fiveGalQuantity = 0;
      });
    }
    driverName.clear();
  }

  void pushPhoto() {
    if (fullBucketQuantity != 0) {
      transportType = 1;
    } else if (fiveGalQuantity != 0) {
      transportType = 2;
    }
    Navigator.pushNamed(context, '/send', arguments: {
      'driverId': data['driverId'],
      'qrName': data['driverName'],
      'inputName': this.driverName.text,
      'machineId': data['machineId'],
      'saltType': this.saltType,
      'transportType': this.transportType,
      'fbQuantity': this.fullBucketQuantity,
      'fgQuantity': this.fiveGalQuantity,
      'licenseImg': data['licenseImg'],
      'plateImg': data['plateImg'],
      'license64': data['license64'],
      'plate64': data['plate64']
    });
  }

  void fbAdd() {
    setState(() {
      fullBucketQuantity += 0.5;
    });
  }

  void fbRemove() {
    setState(() {
      fullBucketQuantity -= 0.5;
    });
  }

  void fgAdd() {
    setState(() {
      fiveGalQuantity += 0.5;
    });
  }

  void fgRemove() {
    setState(() {
      fiveGalQuantity -= 0.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    data = ModalRoute.of(context).settings.arguments;
    print(data);

    return Scaffold(
        appBar: AppBar(
          leading: BackButton(color: Colors.cyan),
          backgroundColor: Colors.white,
          title: Text("Dispatch Data", style: TextStyle(color: Colors.cyan)),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (data['driverId'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            child: Text('Hi, ' + data['driverName']),
                          )
                      ],
                    ),
                  ),
                if (data['driverId'] != null)
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Salt Type'),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(color: Colors.grey)),
                    child: DropdownButtonHideUnderline(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: DropdownButton(
                            value: saltType,
                            items: [
                              DropdownMenuItem(
                                child: Text("Normal",
                                    style:
                                        TextStyle(color: Colors.grey.shade700)),
                                value: 1,
                              ),
                              DropdownMenuItem(
                                child: Text("Treated",
                                    style:
                                        TextStyle(color: Colors.grey.shade700)),
                                value: 2,
                              ),
                              DropdownMenuItem(
                                  child: Text("Mix",
                                      style: TextStyle(
                                          color: Colors.grey.shade700)),
                                  value: 3)
                            ],
                            onChanged: (value) {
                              setState(() {
                                saltType = value;
                                if (data['driverId'] == null) {
                                  myFocusNode.requestFocus();
                                }
                              });
                            }),
                      ),
                    ),
                  ),
                ),
                if (data['driverId'] == null) SizedBox(height: 10),
                if (data['driverId'] == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Company Driver'),
                  ),
                if (data['driverId'] == null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: TextField(
                        focusNode: myFocusNode,
                        controller: driverName,
                        decoration: const InputDecoration(
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(),
                          hintText: 'Please enter your name',
                        )),
                  ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Transport Type'),
                ),
                if (fiveGalQuantity == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Card(
                      child: Column(children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                                color: Colors.cyan.shade200,
                                child: Image.asset(
                                    'assets/images/full_bucket.png')),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text('Full Bucket',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                                icon: Icon(Icons.remove),
                                iconSize: 50,
                                onPressed: fbRemove),
                            Text('$fullBucketQuantity',
                                style: TextStyle(fontSize: 25)),
                            IconButton(
                                icon: Icon(Icons.add),
                                iconSize: 50,
                                onPressed: fbAdd)
                          ],
                        )
                      ]),
                    ),
                  ),
                if (fullBucketQuantity == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: fullBucketQuantity != 0
                        ? null
                        : Card(
                            child: Column(children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                      color: Colors.cyan.shade200,
                                      child: Image.asset(
                                          'assets/images/five_gallon.png')),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text('5 Gallon',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.remove),
                                      iconSize: 50,
                                      onPressed: fgRemove),
                                  Text('$fiveGalQuantity',
                                      style: TextStyle(fontSize: 25)),
                                  IconButton(
                                      icon: Icon(Icons.add),
                                      iconSize: 50,
                                      onPressed: fgAdd)
                                ],
                              )
                            ]),
                          ),
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
                if (fullBucketQuantity != 0 ||
                    fiveGalQuantity != 0 ||
                    driverName.text != '')
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
                if (fullBucketQuantity != 0 && driverName.text != '' ||
                    fiveGalQuantity != 0 && driverName.text != '')
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
                    onPressed: () => pushPhoto(),
                  ),
                if (fullBucketQuantity != 0 && data['driverId'] != null ||
                    fiveGalQuantity != 0 && data['driverId'] != null)
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
                    onPressed: () => pushPhoto(),
                  ),
              ],
            ),
          ),
        ));
  }
}
