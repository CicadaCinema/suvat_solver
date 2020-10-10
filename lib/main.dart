import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

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
  static List _suvatSolutions = [Map.from(_suvatValues), Map.from(_suvatValues)];
  static bool _ambiguousCase = false;
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
    // set up coefficients in case of a quadratic
    double a, b, c;

    switch (missingVariable) {
      case 's':
        return {(values['v']-values['u'])/values['a']};
      case 'u':
        // ambiguous case - define a quadratic in t
        a = -0.5*values['a'];
        b = values['v'];
        c = -values['s'];
        break;
      case 'v':
        // ambiguous case - define a quadratic in t
        a = 0.5*values['a'];
        b = values['u'];
        c = -values['s'];
        break;
      case 'a':
        return {(2*values['s'])/(values['u']+values['v'])};
      default:
        throw new Exception('Missing variable assigned invalid value in function calculate_t.');
    }

    // ignore: dead_code
    double discriminant = pow(b, 2) - 4*a*c;
    if (discriminant<0){
      // no real solution
      return {};
    }
    // return the solutions to the quadratic
    return {
      (-b+sqrt(discriminant))/(2*a),
      (-b-sqrt(discriminant))/(2*a)
    };
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

  void suvatCalculation(Map<String, double> values){
    // ambiguous case when t AND u/v are unknown
    _ambiguousCase = values['t']==null && (values['u']==null || values['v']==null);

    // find missing variables
    List<String> missingVariablesNames = [];
    values.forEach((key, value) {
      if (value == null){
        missingVariablesNames.add(key);
      }
    });

    // set the first three values
    _suvatSolutions[0] = Map.from(_suvatValues);

    if (_ambiguousCase){
      // placeholder
      _suvatSolutions[0] = Map.from(_suvatValues);
      _suvatSolutions[1] = Map.from(_suvatValues);
    } else {
      // clear the second solution set
      values.forEach((key, value) {
        _suvatSolutions[1][key] = null;
      });

      // calculate answer as usual
      values.forEach((key, value) {
        if (missingVariablesNames.contains(key)){
          String otherUnknown = missingVariablesNames[1-missingVariablesNames.indexOf(key)];
          switch (key) {
            case 's':
              _suvatSolutions[0][key] = calculate_s(values, otherUnknown).first;
              break;
            case 'u':
              _suvatSolutions[0][key] = calculate_u(values, otherUnknown).first;
              break;
            case 'v':
              _suvatSolutions[0][key] = calculate_v(values, otherUnknown).first;
              break;
            case 'a':
              _suvatSolutions[0][key] = calculate_a(values, otherUnknown).first;
              break;
            case 't':
              _suvatSolutions[0][key] = calculate_t(values, otherUnknown).first;
              break;
          }
        }
      });
    }

  }

  void suvatVerify(){
    if (_formKey.currentState.validate()) {
      // perform functions below if no strings appear in the form fields
      if (countNullsInMap(_suvatValues) == 2){
        // everything looks good!
        setState(() {});
        suvatCalculation(_suvatValues);
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
                return null;
              }
              _suvatValues[item] = null;
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

        Row(
          children: [
            // ALL this is inefficient - columns inside a large column

            Spacer(flex: 2),

            // show solutions[0]
            Column(children: [
              for(String item in 'suvat'.split('')) Column(children: [
                Text(
                  _SuvatFormState._suvatNames[item].toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_SuvatFormState._suvatSolutions[0][item].toString()),
              ],),
            ],),

            _SuvatFormState._ambiguousCase? Spacer(flex: 3): SizedBox.shrink(),

            // show solutions[1] - only if this is an ambiguous case
            _SuvatFormState._ambiguousCase? Column(children: [
              for(String item in 'suvat'.split('')) Column(children: [
                Text(
                  _SuvatFormState._suvatNames[item].toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_SuvatFormState._suvatSolutions[1][item].toString()),
              ],),
            ],):SizedBox.shrink(),

            Spacer(flex: 2)
          ]
        ),

        
        ]
      ),
    );
  }
}