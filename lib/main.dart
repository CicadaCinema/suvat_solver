import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// it looks like this package is unnecessary
// import 'package:flutter/services.dart';
import 'dart:math';

// an exception with custom text
class CustomException implements Exception {
  String cause;
  CustomException(this.cause);
}

// TODO: component/unit testing??
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // define app title and theme data
      title: 'Suvat Solver',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        primarySwatch: Colors.indigo,
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.indigo,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      // initially go to form page - to get inputs from user
      home: SuvatForm(title: 'Solver'),
    );
  }
}

class SuvatForm extends StatefulWidget {
  SuvatForm({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _SuvatFormState createState() => _SuvatFormState();
}

class _SuvatFormState extends State<SuvatForm> {
  // this form key helps with form-related methods
  final _formKey = GlobalKey<FormState>();

  // a template map to store the user's inputs
  static Map<String, double> _suvatValues = {'s': null, 'u': null, 'v': null, 'a': null, 't': null};
  static List _suvatSolutions = new List(2);
  static bool _ambiguousCase = false;
  static const Map<String, String> _suvatNames = {'s': 'Displacement', 'u': 'Initial velocity', 'v': 'Final velocity', 'a': 'Acceleration', 't': 'Time'};

  // this method simply counts the number of null values in a map
  int countNullsInMap(Map inputMap){
    int count = 0;

    inputMap.forEach((key, value) {
      if(value == null){
        count++;
      }
    });

    return count;
  }

  /*
  these methods take in a map containing the known suvat values and a string
  with the 'missing variable' - the one that's not involved in the calculation;
  they return a set containing the value of the desired variable (eg calculateS
  will always return a set containings solutions for s);
  sometimes the length of the returned set is 1, sometimes it is 2
  */
  Set<double> calculateS(Map<String, double> values, String missingVariable){
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
        throw new Exception('Missing variable assigned invalid value in function calculateS.');
    }
  }
  Set<double> calculateT(Map<String, double> values, String missingVariable){
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
        throw new Exception('Missing variable assigned invalid value in function calculateT.');
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
  Set<double> calculateU(Map<String, double> values, String missingVariable){
    switch (missingVariable) {
      case 's':
        return {(values['v'] - values['a']*values['t'])};
      case 't':
        // heed this exception, but the code below can stay
        throw new Exception('This case should never be reached. For unknown u/v and t, t is always calculated first.');
        // ambiguous case
        // ignore: dead_code
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
        throw new Exception('Missing variable assigned invalid value in function calculateU.');
    }
  }
  Set<double> calculateV(Map<String, double> values, String missingVariable){
    switch (missingVariable) {
      case 's':
        return {(values['u'] + values['a']*values['t'])};
      case 't':
        // heed this exception, but the code below can stay
        throw new Exception('This case should never be reached. For unknown u/v and t, t is always calculated first.');
        // ambiguous case
        // ignore: dead_code
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
        throw new Exception('Missing variable assigned invalid value in function calculateV.');
    }
  }
  Set<double> calculateA(Map<String, double> values, String missingVariable){
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
        throw new Exception('Missing variable assigned invalid value in function calculateA.');
    }
  }

  // TODO: implement a warning when the user enters impossible values
  // this method uses the individual components above to assemble solutions
  // these are saved in _suvatSolutions rather than being returned by the function
  void suvatCalculation(Map<String, double> values){
    // ambiguous case is when t AND u/v are unknown
    _ambiguousCase = values['t']==null && (values['u']==null || values['v']==null);

    // find missing variables and add their keys/names to a list
    List<String> missingVariablesNames = [];
    values.forEach((key, value) {
      if (value == null){
        missingVariablesNames.add(key);
      }
    });

    // assign known values to both solution sets - now only the unknown values need to be filled in
    // two additional maps must be explicitly created to copy the 'values' map instead of referencing it
    Map<String, double> map1 = new Map.from(values);
    Map<String, double> map2 = new Map.from(values);
    _suvatSolutions[0] = map1;
    _suvatSolutions[1] = map2;

    if (_ambiguousCase){
      // the time variable (t) is always unknown in an ambiguous case
      Set<double> tSolutions;
      // get the key of the other unknown variable from the list created earlier
      String otherUnknown = missingVariablesNames[1-missingVariablesNames.indexOf('t')];

      // find the two possible values of t
      tSolutions = calculateT(values, otherUnknown);
      _suvatSolutions[0]['t'] = tSolutions.first;
      _suvatSolutions[1]['t'] = tSolutions.last;

      // t is now known, so there is only one possible u/v value for each solution
      switch (otherUnknown) {
        case 'u':
          _suvatSolutions[0][otherUnknown] = calculateU(_suvatSolutions[0], 's').first;
          _suvatSolutions[1][otherUnknown] = calculateU(_suvatSolutions[1], 's').last;
          break;
        case 'v':
          _suvatSolutions[0][otherUnknown] = calculateV(_suvatSolutions[0], 's').first;
          _suvatSolutions[1][otherUnknown] = calculateV(_suvatSolutions[1], 's').last;
          break;
      }
    } else {
      // loop over each input value and check if it is unknown
      values.forEach((key, value) {
        if (missingVariablesNames.contains(key)){
          // get the key/name of the OTHER unknown value
          String otherUnknown = missingVariablesNames[1-missingVariablesNames.indexOf(key)];

          // find the unknown value, specifying the other unknown when needed
          Set<double> result;
          switch (key) {
            case 's':
              result = calculateS(values, otherUnknown);
              break;
            case 'u':
              result = calculateU(values, otherUnknown);
              break;
            case 'v':
              result = calculateV(values, otherUnknown);
              break;
            case 'a':
              result = calculateA(values, otherUnknown);
              break;
            case 't':
              result = calculateT(values, otherUnknown);
              break;
          }
          // add this unknown value (certainly only one solution) to the solution set
          _suvatSolutions[0][key] = result.first;
        }
      });
    }
  }

  void processSuvatInputs(){
    // two fields are left blank
    if (countNullsInMap(_suvatValues) == 2){
      setState(() {}); // not sure why this is needed
      suvatCalculation(_suvatValues);
    // an invalid number of fields are filled
    } else {
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

  // build the bottom bar
  Widget bottomBar() {
    return BottomAppBar(
      child: Row(children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          // reset suvat inputs
          child: RaisedButton(
            child: Text('Reset'),
            onPressed: () {
              _formKey.currentState.reset();
              _suvatValues = {'s': null, 'u': null, 'v': null, 'a': null, 't': null};
            }
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          // go to the solutions page without solving suvats to view the previous solution set
          child: RaisedButton(
            child: Text('View Previous'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SuvatSolutions()),
              );
            },
          ),
        ),
      ],),
    );
  }

  // the large 'Submit' button
  Widget submitButton() {
    return FloatingActionButton.extended(
      // if the form validates, solve for the two unknown values and go to the solutions page
      onPressed: () {
        if (_formKey.currentState.validate()) {
          processSuvatInputs();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SuvatSolutions()),
          );
        }
      },
      label: Text('Submit!'),
      icon: Icon(Icons.check),
      backgroundColor: Colors.pink,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget form = Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            // create lots of TextFormField textboxes
            for(String item in 'suvat'.split('')) TextFormField(
              // validator first ensures that the field CAN be parsed as a number
              // then it adds the value to the map of inputs and returns without an error
              // a blank input also counts as vaid - but the corresponding input in the values
              // map is filled in as null - signifying an unknown to be determined
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
            Spacer(),
          ],
        ),
      )
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Solver'),
      ),
      body: form,
      bottomNavigationBar: bottomBar(),
      floatingActionButton: submitButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

// this stateless widget takes solutions from the state of the suvat form and displays them
class SuvatSolutions extends StatelessWidget {
  // this method returns a nicely formatted column corresponding to the solution set provided as input
  Widget showSolutionBlock(Map<String, double> solutionSet)
  {
    List<Widget> columnItems = new List<Widget>();

    for(String item in 'suvat'.split('')) {
      // fixed padding
      columnItems.add(SizedBox(height: 10));
      // variable name in bold
      columnItems.add(Text(
        _SuvatFormState._suvatNames[item].toString(),
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      // variable value
      columnItems.add(Text(solutionSet[item].toString()));
    }
    return new Column(children: columnItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Solutions"),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Spacer(),
                // always show first solution set
                showSolutionBlock(_SuvatFormState._suvatSolutions[0]),
                // show large spacer - only if this is an ambiguous case
                _SuvatFormState._ambiguousCase? Spacer(flex: 3) : SizedBox.shrink(),
                // show solutions[1] - only if this is an ambiguous case
                _SuvatFormState._ambiguousCase? showSolutionBlock(_SuvatFormState._suvatSolutions[1]) : SizedBox.shrink(),
                Spacer(),
              ]
            ),
          ]
        ),
      ),
      // allow user to pop back to the previous screen
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
        label: Text('Go back!'),
        icon: Icon(Icons.arrow_back),
        backgroundColor: Colors.pink,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}