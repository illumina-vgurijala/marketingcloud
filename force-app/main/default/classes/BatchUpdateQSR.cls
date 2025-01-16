/**
 *    @author Aditi Joshi
 *    @date   25-Nov-2020
 *    @description  Batch Class to update Question fields in QSR records
*/

global with sharing class BatchUpdateQSR implements Database.Batchable<sObject>, Database.Stateful{
	
	private String strQuery;
    public Set<String> setNonUpdatedQSRErrors = new Set<String>();
    public static final String CODEPARAMETERNAME = 'EmailIdsIVDR';
    public String idNewRecordTypeId;
    @TestVisible static boolean boolEmailSent= false;
	public static Boolean boolIsTestRunning = false;
	
	/*Query for updating fields through batch*/
    public BatchUpdateQSR() {
		this.strQuery = 'SELECT Id,Q3_Question__c,Q4_Question__c,Q5_Question__c,Q6_Question__c,Q7_Question__c,Q8_Question__c,Q9_Question__c, Q10_Question__c FROM Qualtrics_Survey_Response__c';
		
    }
	
	/*@description Start Method For the Apex JOb*/
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(this.strQuery);
    }
   
	/*@description Execute Method For the Apex JOb*/
	global void execute(Database.BatchableContext bc, list<Sobject> scope){
        List<Qualtrics_Survey_Response__c> lstUpdatedQSR = new List<Qualtrics_Survey_Response__c>();
        for(Qualtrics_Survey_Response__c objQSR : (List<Qualtrics_Survey_Response__c>)scope){
			if(String.IsBlank(objQSR.Q3_Question__c)){
				objQSR.Q3_Question__c = 'NA';  
			}
			if(String.IsBlank(objQSR.Q4_Question__c)){
				objQSR.Q4_Question__c = 'NA';  
			}
			if(String.IsBlank(objQSR.Q5_Question__c)){
				objQSR.Q5_Question__c = 'NA';  
			}
			if(String.IsBlank(objQSR.Q6_Question__c)){
				objQSR.Q6_Question__c = 'NA';  
			}
			if(String.IsBlank(objQSR.Q7_Question__c)){
				objQSR.Q7_Question__c = 'NA';  
			}
			if(String.IsBlank(objQSR.Q8_Question__c)){
				objQSR.Q8_Question__c = 'NA';  
			}
			if(String.IsBlank(objQSR.Q9_Question__c)){
				objQSR.Q9_Question__c = 'NA';  
			}
			if(String.IsBlank(objQSR.Q10_Question__c)){
				objQSR.Q10_Question__c = 'NA';  
			}
            
            lstUpdatedQSR.add(objQSR);
        }
        if(!lstUpdatedQSR.isEmpty()){
            Database.SaveResult[] result = Database.update(lstUpdatedQSR, false);
            Integer intCount = 0;
            for (Database.SaveResult sr : result){
                if(!sr.isSuccess()){
                    for(Database.Error err : sr.getErrors()){
                        setNonUpdatedQSRErrors.add(lstUpdatedQSR.get(intCount).id +' : '+ err.getStatusCode() + ': ' + err.getMessage()+ ': ' + err.getFields());
                    }
                }
                intCount++;
            }
        }
    }
    
	/*@description Finish Method For the Apex JOb*/
    global void finish(Database.BatchableContext bc){
        if(!setNonUpdatedQSRErrors.isEmpty() || !boolIsTestRunning){
            CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
            List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> strEmailId = new List<String>();
            if(!Test.isRunningTest()){
				strEmailId.addAll(objCodeParam[0].Value__c.split(';'));
            }
			else{
				strEmailId.add('ajoshi@illumina.com');
			}
            email.setToAddresses(strEmailId);
            String subject = 'ACTION NEEDED: QSR Questions update failed';
            email.setSubject(subject);
            String strBody = 'Following QSR were not updated : </br>';
            for(String str : setNonUpdatedQSRErrors){
                strBody = strBody + str+'</br>';
			}
            email.setHtmlBody(strBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            boolEmailSent = true;
        }
    }
}