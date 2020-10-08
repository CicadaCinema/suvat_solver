import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

Set<double> calculate_s(Map<String, double> values, String missingVariable){
  switch (missingVariable) {
    case 't':
      return {(pow(values['v'],2) - pow(values['u'],2))/(2*values['a'])};
    case 'v':
      return {(values['u']*values['t'] + 0.5*values['a']*pow(values['t'],2))};
    case 'u':
      return {(values['v']*values['t'] - 0.5*values['a']*pow(values['t'],2))};
    case 'a':
      return {(0.5*(values['v']+values['u'])*values['t'])};
    default:
      throw new Exception('Missing variable assigned invalid value in function calculate_s.');
  }
}
Set<double> calculate_t(Map<String, double> values, String missingVariable){
  switch (missingVariable) {
    case 's':
      return {(values['v']-values['u'])/values['a']};
    case 'u':
      // ambiguous case
      double discriminant = pow(values['u'],2) - 4*0.5*values['a']*(-values['s']);
      if (discriminant<0){
        // no real solution
        return {};
      } 
      // there is a solution (or two)
      return {
        (-values['u']+discriminant)/(2*0.5*values['a']),
        (-values['u']-discriminant)/(2*0.5*values['a'])
      };
    case 'v':
      // ambiguous case
      double discriminant = pow(values['u'],2) - 4*(-0.5)*values['a']*(-values['s']);
      if (discriminant<0){
        // no real solution
        return {};
      } 
      // there is a solution (or two)
      return {
        (-values['u']+discriminant)/(2*(-0.5)*values['a']),
        (-values['u']-discriminant)/(2*(-0.5)*values['a'])
      };
    case 'a':
      return {(2*values['s'])/(values['u']+values['v'])};
    default:
      throw new Exception('Missing variable assigned invalid value in function calculate_t.');
  }
}
Set<double> calculate_u(Map<String, double> values, String missingVariable){
  switch (missingVariable) {
    case 's':
      return {(values['v'] - values['a']*values['t'])};
    case 't':
      // ambiguous case
      double answer;
      answer = sqrt(pow(values['v'],2)-2*values['a']*values['s']);
      if (answer.isNaN){
        // no real solution
        return {};
      }
      // there is a solution (or two)
      return {answer, -answer};
    case 'v':
      return {(values['s']-0.5*values['a']*pow(values['t'],2))/(values['t'])};
    case 'a':
      return {(((2*values['s'])/values['t']) - values['v'])};
    default:
      throw new Exception('Missing variable assigned invalid value in function calculate_u.');
  }
}
Set<double> calculate_v(Map<String, double> values, String missingVariable){
  switch (missingVariable) {
    case 's':
      return {(values['u'] + values['a']*values['t'])};
    case 't':
      // ambiguous case
      double answer;
      answer = sqrt(pow(values['u'],2)+2*values['a']*values['s']);
      if (answer.isNaN){
        // no real solution
        return {};
      }
      // there is a solution (or two)
      return {answer, -answer};
    case 'u':
      return {(values['s']+0.5*values['a']*pow(values['t'],2))/(values['t'])};
    case 'a':
      return {(((2*values['s'])/values['t']) - values['u'])};
    default:
      throw new Exception('Missing variable assigned invalid value in function calculate_v.');
  }
}
Set<double> calculate_a(Map<String, double> values, String missingVariable){
  switch (missingVariable) {
    case 's':
      return {(values['v']-values['u'])/values['t']};
    case 't':
      return {(pow(values['v'],2) - pow(values['u'],2))/(2*values['s'])};
    case 'u':
      return {(values['s'] - values['v']*values['t'])/(-0.5*pow(values['t'],2))};
    case 'v':
      return {(values['s'] - values['u']*values['t'])/(0.5*pow(values['t'],2))};
    default:
      throw new Exception('Missing variable assigned invalid value in function calculate_a.');
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suvat Solver',
      theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Suvat Solver Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
    title: Text(widget.title),
    ),
    body: Column(
      children: <Widget>[
        SuvatForm(),
          RaisedButton(
            child: Text(_SuvatFormState._suvatValues['s'].toString()),
            color: Colors.blue,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecondRoute()),
              );
            },
          ),
        ],
    ),
  );
  }
}

class CustomException implements Exception {
  String cause;
  CustomException(this.cause);
}

class SuvatForm extends StatefulWidget {
  @override
  _SuvatFormState createState() => _SuvatFormState();
}

class _SuvatFormState extends State<SuvatForm> {

  final _formKey = GlobalKey<FormState>();

  static Map<String, double> _suvatValues = {'s': null, 'u': null, 'v': null, 'a': null, 't': null};
  static const Map<String, String> _suvatNames = {'s': 'Displacement', 'u': 'Initial velocity', 'v': 'Final velocity', 'a': 'Acceleration', 't': 'Time'};

  int countNullsInMap(Map inputMap){
    int count = 0;

    inputMap.forEach((key, value) {
      if(value == null){
        count++;
      }
    });

    return count;
  }

  void suvatVerify(){
    if (_formKey.currentState.validate()) {
      // perform functions below if no strings appear in the form fields
      if (countNullsInMap(_suvatValues) == 2){
        // everything looks good!
        setState(() {});
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SecondRoute()),
        );
      } else {
        // an invalid number of fields are filled
        showDialog<void>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Exactly three values must be specified'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  int suvatCalculation(Map<String, double> values){
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[

          // create lots of TextFormField textboxes
          for(String item in 'suvat'.split('')) TextFormField(
            validator: (value) {
              if (value != '') {
                if (double.tryParse(value) == null){
                return 'Value must be a number';
                }
              _suvatValues[item] = double.parse(value);
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: _suvatNames[item],
            ), 
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(children: [
              RaisedButton(
                onPressed: () {
                  suvatVerify();  
                },
                child: Text('Submit and go to the second page'),
              ),
              RaisedButton(
                onPressed: () {
                  _formKey.currentState.reset();
                  _suvatValues = {'s': null, 'u': null, 'v': null, 'a': null, 't': null};
                },
                child: Text('Reset'),
              ),
            ],)
          ),
          Text(_suvatValues['s'].toString()),
        ],
      ),
    );
  }
}

class SecondRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Second Route"),
      ),
      body: Column(
        children: [
          RaisedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Go back!'),
        ),
        Text('Answer'),
        Text(_SuvatFormState._suvatValues['s'].toString()),
        ]
      ),
    );
  }
}