({
    recordUpdated: function(component, event, helper) {
        helper.handleRecordUpdate(component, event);
    },
    loadData : function(component, event, helper) {
    	helper.loadData(component);
    },
    saveRecord : function(component, event, helper) {
        helper.saveData(component,helper);
    },
    hideConfirmModal : function(component, event, helper) {
        helper.hideConfirm(component,helper);
    },
    revertOldValue : function(component, event, helper) {
        helper.revertOldData(component,helper);
    },
    saveRecordForPartsNotUsed : function(component, event, helper){
        helper.saveDataForPartsNotUsed(component,helper);
    }
})