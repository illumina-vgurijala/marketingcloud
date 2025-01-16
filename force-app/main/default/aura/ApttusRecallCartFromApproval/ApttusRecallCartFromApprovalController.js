({
   recall : function(component, event, helper) {
       //helper.loadpage(component,helper);
       // helper.saveProposal(component, helper);
       helper.recallQuote(component, event, helper);
   },
    
   cancel : function(component, event, helper){
      let closeEvent = $A.get("e.force:closeQuickAction");
      if(closeEvent){
        closeEvent.fire();
      } else {
        alert('force:closeQuickAction event is not supported in this Ligthning Context');
      }
   } 
    
   
   
   
})