/**
* @author PA
* @date 17th June 2022
*
* @description DCP-52665 Queueable Class for Email Messages to update case fields 
*/ 

public with sharing class EmailMessages_CaseHelper implements Queueable{
    
    private static final String LOG_TITLE = 'EmailMessages_CaseHelper';
    private static final String LOG_METHOD_NAME = 'methodName';
    private static final String CASE_GROUPING_FIELD_VALUE = 'Instrument Service';
    private static final String METHOD_UPDATEGROUPINGFIELDRECORDS_ON_CASE = 'updateCaseGroupingField';
    private static final String CASE_GROUPING_FIELD_VALUE_SW = 'Software'; //CMCM-9331
    List<SObject> emailMessageRecordsList = new List<SObject>();
    String methodName;
    

    /*******************************************************************************************************
    * @description Constructor
    * @param emailMessageRecords List<sObject>
    * @param methodName List<sObject>
    * @return
    */
    public EmailMessages_CaseHelper(String methodName, List<Sobject> records) {
        this.emailMessageRecordsList = records;
        this.methodName = methodName;
    }

     
    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
             
            if(methodName == METHOD_UPDATEGROUPINGFIELDRECORDS_ON_CASE) {
                updateCaseGroupingField(emailMessageRecordsList);
            }
        } catch(Exception ex) {  
            ApexExceptions.emit(LOG_TITLE+'.'+ LOG_METHOD_NAME, ex); 
            throw ex; 
        }
        
    }


    /*
    * @author PA
    * @Description Logic to update Grouping field as Instrument Service based on the to email address
    * @param set of Case Ids to update
    * @return void
    */
    public static void updateCaseGroupingField(List<EmailMessage> records) {
        List<Case> toBeUpdatedCasesList =  new List<Case>();
        for(EmailMessage objEmailMsg : records){            
            if(objEmailMsg.Incoming){
                if(
                    (  
                        (   
                            objEmailMsg.ToAddress == null 
                            || 
                            (objEmailMsg.ToAddress != null &&
                            !objEmailMsg.ToAddress.contains(Label.Email2CaseGroupingAddressTechSupport) &&
                            !objEmailMsg.ToAddress.contains(Label.Email2CaseGroupingAddressChinaSupport))
                        )
                        &&
                        (
                            objEmailMsg.CcAddress == null
                            ||
                            (objEmailMsg.CcAddress != null && 
                            !objEmailMsg.CcAddress.contains(Label.Email2CaseGroupingAddressTechSupport) &&
                            !objEmailMsg.CcAddress.contains(Label.Email2CaseGroupingAddressChinaSupport))
                        )
                    ) && 
                    (  
                       ( 
                        (objEmailMsg.ToAddress != null && 
                         objEmailMsg.ToAddress.contains(Label.Email2CaseInstrumentServiceId)) ||
                        (objEmailMsg.CcAddress != null && objEmailMsg.CcAddress.contains(Label.Email2CaseInstrumentServiceId))

                       )
                       //CMCM-11952 bugfix
                       ||
                       (
                        (objEmailMsg.ToAddress != null && 
                         objEmailMsg.ToAddress.contains(Label.Email2CaseInstrumentServiceDLId)) ||
                        (objEmailMsg.CcAddress != null && objEmailMsg.CcAddress.contains(Label.Email2CaseInstrumentServiceDLId))
                       )
                    
                    )
                    &&
                    objEmailMsg.ParentId != null                    
                ){
                    Case caseObj = new Case(Id = objEmailMsg.ParentId);
                    caseObj.Grouping__c = CASE_GROUPING_FIELD_VALUE;
                    
                    toBeUpdatedCasesList.add(caseObj);
                } 
                //CMCM-9331 start
                else if(
                    objEmailMsg.FromAddress != null && 
                    objEmailMsg.FromAddress.equalsIgnoreCase(Label.Email2CaseFromAddressPartek)
                    )
                {
                    Case caseObj = new Case(Id = objEmailMsg.ParentId);
                    caseObj.Grouping__c = CASE_GROUPING_FIELD_VALUE_SW;
                    
                    toBeUpdatedCasesList.add(caseObj);
                }
                //CMCM-9331 end
            }
        }
        // Update case records
        if(!toBeUpdatedCasesList.IsEmpty()) {
            update toBeUpdatedCasesList;  
        }
    }      
}
