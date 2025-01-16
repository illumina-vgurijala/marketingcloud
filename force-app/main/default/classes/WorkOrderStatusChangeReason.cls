/***************************************************************************************************************************************
 * NAME   : WorkOrderStatusChangeReason
 * DESCRIPTION  : for WorkOrderStatusChangeReason.cmp. 
 				  DCP-720 Display popup to enter Reason while Work Order status change.
 *    			  DCP-802 Display popup for Work Order Status Closed/Completed When Instrument Down is checked.
 * @AUTHOR : Debalina
 * @DATE   : 16-May-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Debalina             16-May-2018          Initial Version
 * Debalina             31-May-2018          DCP-802 Added custom labels
  ****************************************************************************************************************************************/ 


public with sharing class WorkOrderStatusChangeReason {

	@TestVisible
	static List<Work_Order_Setting__mdt> lstStatusMetadata { 
	    get {
	        if ( lstStatusMetadata == null )
	            lstStatusMetadata = [SELECT Work_Order_Status__c,
										    DeveloperName 
						   		    FROM Work_Order_Setting__mdt]; 
	        return lstStatusMetadata;
	    } 
	    set; 
	}

	 /*
    *  @AUTHOR:  Debalina	
    *  @DESCRIPTION:This method loads initial data required.   
    *  @PARAM :  NA
    *  @RETURN:  JSON string with all relevant data
    */
    @AuraEnabled
	public static String loadPageData(Id idWorkOrder) {
		String strJSON = '';
		try{
            system.debug('## idWorkOrder ' + idWorkOrder);
            SVMXC__Service_Order__c objWorkorder = new WorkOrdersSelector().selectNumberOfPartsAndToolsForWorkOrder(idWorkOrder);
			List<String> lstReasonStatus = new List<String>();
			for(Work_Order_Setting__mdt objStatus: lstStatusMetadata){
				lstReasonStatus.add(objStatus.Work_Order_Status__c);	
			}

			List<String> lstCompletedClosed = new List<String>{System.label.Closed,
															 System.label.Completed};
			strJSON = 	'{"lstReasonStatus":'+JSON.serialize(lstReasonStatus)
						+',"lstCompletedClosed":' + JSON.serialize(lstCompletedClosed)
		        		+',"MapLabelError":'+JSON.serialize(loadLabelAndError())
                        +',"workOrderRecord":'+JSON.serialize(objWorkorder)
		        		+ '}';							
		}catch(Exception e){
			strJSON = 'Fail';
			System.debug('Exception on Class : WorkOrderStatusChangeReason - loadPageData, Error : ' +
                         e.getMessage() +
                         ' Line Number : ' +
                         e.getLineNumber() +
                         ' Cause : ' +
                         e.getCause() +
                         ' Type : ' +
                         e.getTypeName());
			throw new AuraHandledException('Error : '+ e.getMessage());
		}

	    return strJSON;
	}

	/*
    *  @AUTHOR:  Debalina	
    *  @DESCRIPTION:This method loads all error and custom labels for lightning component   
    *  @PARAM :  NA
    *  @RETURN:  Map<String,String> with <custom label name,value>
    */
	@TestVisible
    private static Map<String,String> loadLabelAndError() {

        Map<String,String> mapLabelAndError = new Map<String, String>();
		mapLabelAndError.put('Reason',System.label.Reason);
		mapLabelAndError.put('Save',System.label.Save);
		mapLabelAndError.put('Please_Enter_Reason',System.label.Please_Enter_Reason);
		mapLabelAndError.put('Save_Success',System.label.Save_Success);
		mapLabelAndError.put('Success',System.label.Success);
		mapLabelAndError.put('Error',System.label.Error);
		mapLabelAndError.put('Problem_Saving',System.label.Problem_Saving);
		mapLabelAndError.put('Offline',System.label.Offline);
		mapLabelAndError.put('User_offline',System.label.User_offline);
		mapLabelAndError.put('Unknown_Problem',System.label.Unknown_Problem);
		mapLabelAndError.put('ConfirmMessageBeforeCompletedClosedWO',System.label.ConfirmMessageBeforeCompletedClosedWO);
		mapLabelAndError.put('Cancel',System.label.WorkOrderModalStatusChangeCancel);
		mapLabelAndError.put('RecordSaveCancelled',System.label.RecordSaveCancelled);

        return mapLabelAndError;
    }
}