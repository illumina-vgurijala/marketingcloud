    var COUNT = 0;
    
    var incrementCounter = function(that) {
      if (that.checked) {
        COUNT = COUNT + 1;
      } else {
        COUNT = COUNT -1;
      }
      if (COUNT > 5) {
        alert("You are only allowed to select 5 Accounts.");
        that.checked = false;
        COUNT--;

      }
    }
    
    var resetCounter = function() {
      COUNT = 0;
    }

function updateExprString() {
  var sequence_str = '',
      validationView = j$('.validator--expr'),
      filterExprArr = j$('.filterSequence'),
      space = ' ',
      and = 'AND';

  filterExprArr.each(function(index, value) {
      var that = j$(this);

      if(index === filterExprArr.length-1) {
          sequence_str += that.text();
      }
      else {
          sequence_str += that.text() + space + and + space;
      }               
  })
  validationView.val(sequence_str);
}      
function validator(str) {
    var validationView = j$('.filter--set .validator--expr'),
    validationMsg = j$('.filter--set .validator--msg');

    validationView.val(str); 
    
}

function closeSettings(){
  var filterSection = j$('.SettingsPanel');
  if(filterSection) {
    filterSection.hide('slow');
  }
   document.getElementById('showSetting').value = 'Show Settings';
}

function savefunction() {
    doSave();
    redirectToPreviousPage();
}
function saveAsFunction() {
    doSaveAs();
    redirectToPreviousPage();
}
function cancelFunction() {
    doCancel();
}
function deleteField() { 
    doDeleteField();
}
function toggleFilter() {
  var filterSection = j$('.SettingsPanel');
  if(filterSection) {
    filterSection.slideToggle('slow');
  }
  var s = document.getElementById('showSetting').value;
  if (s == 'Show Settings')
    document.getElementById('showSetting').value = 'Hide Settings';
  else
    document.getElementById('showSetting').value = 'Show Settings';
  
}

function validateActions(expr, pCount) {
  var isValid = validateExpression(expr, pCount);
  if (!isValid) {
      j$('.validator--expr').css("border-color", "red");
      DisableButton();
  } else if (isValid) {
      j$('.validator--expr').css("border-color", "green");
      EnableButton();
  }
}

function returnString() {
  return setting();
}

function validateExpression(expression, paramCount) {
  console.debug(expression);
  console.debug(paramCount);
   function validateTokens() {
      var tokens = expression.split(' ');
        for(var index = 0; index < tokens.length; index++) {
         var token = tokens[index];
         token = token.split('(').join('');
         token = token.split(')').join('');;
         var intToken = parseInt(token);
         if(token === '&&' ||
            token === '||' ||
            (NaN != intToken && intToken > 0 && intToken <= paramCount)) {
                continue;
         } else {
            return false;
         }
      }
      return true;
     }
    expression = expression.replace(/AND/g, '&&');
    expression = expression.replace(/and/g, '&&');

    expression = expression.replace(/OR/g, '||');
    expression = expression.replace(/or/g, '||');

    try {
      if(!validateTokens()) {
        return false;
      }
        eval(expression);
    } catch(e) {
        return false;
    }
    return true;
}
function DisableButton() {
    j$('.btn--save').css("border-color", "red");
}
function EnableButton() {
    j$('.btn--save').css("border-color", "#3e9edb");
}

function validateExpr(expr, filterSize, isAdmin) {
    if (expr == '' &&  filterSize == 0) {
        j$('.validator--expr').css("border-color", "green");
        EnableButton();
    } else {
        validateActions(expr, filterSize);
    }
    if (isAdmin == false) {
        DisableButton();
    }
}

$( document ).ready(function() {
  j$ = jQuery.noConflict();
  var accordionItems = new Array();
  var setting = 'Show String';
  

});
