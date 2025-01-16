/**
 * JavaScript utility functions
 * (c) 2014-2015 Apttus, Inc.
 */
function formatNumber(number, prec) {
  if(number == null || number == undefined){
    return number;
  }
  //return (parseFloat(number.toPrecision( prec+(''+number).indexOf('.') )));
  return parseFloat(number).toFixed(prec);
}

