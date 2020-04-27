import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mongo_stitch/flutter_mongo_stitch.dart';
import 'package:sprintf/sprintf.dart';

class HomePage extends StatefulWidget{
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final client = MongoStitchClient();
  var _students = <Student>[];
//    Student(firstName: "Kfir", lastName: "Matityahu", year: 4, grades: [92, 85, 79]),
//    Student(firstName: "Naama", lastName: "Hasson", year: 2, grades: [88, 94, 75, 91])
//  ];

  MongoCollection _collection;

  final _filterOptions = <String>[
    "name",
    "year",
    "grades",
  ];

  final _operatorsOptions = <String>[
    ">",
    ">=",
    "<",
    "<=",
//    "between"
  ];

  String _selectedFilter;
  String _selectedOperator;

  //
  final formKey = GlobalKey<FormState>();
  String _newStudFirstName;
  String _newStudLastName;
  int _newStudYear;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    _collection = client.getDatabase("test").getCollection("students");
    await _fetchStudents();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> list = _students.map((s) => StudentItem(s)).toList();
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Welcome"),
          actions: <Widget>[
            FlatButton(
              child: Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchStudents,
            )
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              _filterRow(),
              SizedBox(height: 20),
              _header(),
                Column(children: list),
            ],
          ),
        ),
        bottomSheet: Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: Form(
            key: formKey,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'First Name'),
                    autocorrect: false,
                    validator: (val) => val.isEmpty ? "can't be empty." : null,
                    onSaved: (val) => _newStudFirstName = val,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Last Name'),
                    autocorrect: false,
                    validator: (val) => val.isEmpty ? "can't be empty." : null,
                    onSaved: (val) => _newStudLastName = val,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Year'),
                    autocorrect: false,
                    validator: (val) => val.isEmpty ? "can't be empty." : null,
                    onSaved: (val) => _newStudYear = int.parse(val),
                  ),
                ),
                SizedBox(width: 12),

                Expanded(
                  flex: 2,
                  child: RaisedButton(
                    child: Text("Add"),
                    onPressed: _insertNewStudent
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(){
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 2,child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold),)),
          Expanded(flex: 1,child: Text("Year", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1,child: Text("Grades Avg.", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  _filterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        DropdownButton(
          value: _selectedFilter,
          items: _filterOptions.map(
                  (name) => DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                  )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFilter =  value;
            });
          },
        ),
        SizedBox(width: 20),
        DropdownButton(
          value: _selectedOperator,
          items: _operatorsOptions.map(
                  (name) => DropdownMenuItem<String>(
                value: name,
                child: Text(name),
              )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedOperator =  value;
            });
          },
        ),
        SizedBox(width: 20),
        Container(
          width: 100,
          child: TextField(
            maxLines: 1,
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: RaisedButton(
            child: Text("Filter"),
            onPressed: (){
              // todo: implemnt this
            },
          ),
        )
      ],
    );
  }

  /// Functions ///

  _fetchStudents() async {
    List documents = await _collection.find();
    _students.clear();
    documents.forEach((document) {
      _students.add(Student.fromDocument(document));
    });
    setState(() {

    });
  }

  _insertNewStudent() async{
    var form = formKey.currentState;


    if(form.validate()){
      form.save();

      var newStudent = Student(
        firstName: _newStudFirstName,
        lastName: _newStudLastName,
        year: _newStudYear,
      );
      await _collection.insertOne(newStudent.asDocument());

      setState(() {
        form.reset();
      });


    }
  }
}

class StudentItem extends StatelessWidget{
  final Student student;

  StudentItem(this.student);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text("${student.firstName} ${student.lastName}", style: TextStyle(fontSize: 20),),
          ),
          Expanded(
              flex: 1,
              child: Text("${student.year}" ,style: TextStyle(fontSize: 18),),
          ),
          Expanded(
              flex: 1,
              child: Text(sprintf("%.2f", [student.gradesAvg]), style: TextStyle(fontSize: 18),)
          ),
        ],
      ),
    );
  }

}

class Student{
  final String firstName;
  final String lastName;
//  final int age;
  final int year;
  final List<int> grades;

  Student({this.lastName, this.firstName, this.grades, this.year});

  double get gradesAvg {
    var sum = 0;
    grades?.forEach((grade) {
      sum+= grade;
    });
    return grades==null || grades.isEmpty ? 0 : sum / grades.length;
  }

  static fromDocument(MongoDocument document){
    return Student(
      firstName: document.get("firstName") ?? "",
      lastName: document.get("lastName") ?? "",
//      age:  document.get("age") ?? 20,
      grades: (document.get("grades")==null
          ?  <int>[]
          : (document.get("grades") as List).map((e) => int.parse("$e")).toList()),
      year: document.get("year") ?? 1
    );
  }

  MongoDocument asDocument() {
    return MongoDocument({
      "firstName": this.firstName,
      "lastName": this.lastName,
      "grades": this.grades ?? [],
      "year": this.year,
    });
  }
}