/*
*/

function _Function_globalIdentifier(fun) {
  var name = null;
  try {
    var re = /return ([\w$]+);/
    name = re.exec(fun.toString())[1]
  } catch (e) {}

  return name;
}

var elmer_fakeFunctions = {}

var _Function_activate = F2(function(name, func) {
  elmer_fakeFunctions[name] = {
    impl: func,
    calls: []
  }

  return func
})

function _Function_deactivate(name) {
  var calls = elmer_fakeFunctions[name].calls

  delete elmer_fakeFunctions[name]

  return calls
}

function _Function_active(name) {
  return elmer_fakeFunctions[name] ? elmer_fakeFunctions[name].impl : null
}

var elmer_storeArg = function(name, arg, currentCall) {
  var callList = elmer_fakeFunctions[name].calls
  var callId = currentCall

  if (callId === undefined) {
    callId = callList.length
    callList[callId] = []
  }

  callList[callId].push(arg)

  return callId
}

var elmer_recordable = function(name, func, currentCall) {
  return function() {
    var callId = elmer_storeArg(name, arguments[0], currentCall)

    var next = func.apply(this, arguments)
    if (typeof(next) !== "function") {
      return next
    }

    return elmer_recordable(name, next, callId)
  }
}

var _Function_recordable = F2(elmer_recordable)
  