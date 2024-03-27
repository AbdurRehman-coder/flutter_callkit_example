

import 'package:flutter/material.dart';

class CallProvider extends ChangeNotifier{
bool callValue=false;

  setcallwindow(bool value){
    callValue=value;
    notifyListeners();
  }
}



