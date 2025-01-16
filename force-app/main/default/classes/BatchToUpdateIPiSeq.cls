/* 
*Description: Batch class to update iSeq/DRAGEN after given days without any update.
*Author: Harsh Shukla
*DCP-28892
*/
public with sharing class BatchToUpdateIPiSeq extends ilib_ScheduleAndBatch implements Schedulable, Database.Stateful{
    public static final Integer IP_UP_GRACE_PERIOD_ILMN = 90;
    public static final Integer IP_UP_GRACE_PERIOD_CP  = 120;
    public static final string CODEPARAMETERNAME = 'Customer_Installable_Product_Codes';
    public Set<String> setNonUpdatedIPErrors = new Set<String>();
    public static List<Database.SaveResult> lstSaveErrors = new List<Database.SaveResult>();
	public static Map<Id, String> mapRecIdToErrors = new Map<Id, String>();
    @TestVisible static boolean boolEmailSent= false;
    public static Boolean boolIsTestRunning = true;
	public static ID batchprocessid;    
    
    /*
    *  Description: Execute method to be called when class is scheduled
    */
    public override void execute(SchedulableContext ctx)
    {
        integer intDefaultBatchsize = 1;
        Map < String, String > params = UtilsSettings.getCustomMetadataMap('Schedule_Batch_for_iSeq');
        Integer batchSize = UtilsSettings.parseIntegerFromSettingsMap(params, 'BatchiSeq', intDefaultBatchsize);
        
        if (batchSize < 1 || batchSize > 100) {
            batchSize = intDefaultBatchsize;
        }
        batchprocessid = Database.executebatch(new BatchToUpdateIPiSeq(), batchSize);
        
    }
    /*
    * Description: Fetch required installed products to process
    */
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        string strQuery;
        Date dtDueDate = Date.Today()-IP_UP_GRACE_PERIOD_ILMN;
        Set<String> productCode = new Set<String>();
        CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
        List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});
        productCode.addAll(objCodeParam[0].Value__c.split(';'));
        strQuery = 'SELECT Id, SVMXC__Company__c, Name, Operation_Status__c, SVMXC__Status__c, Acceptance_Date__c, SVMXC__Date_Installed__c, SVMXC__Date_Shipped__c FROM SVMXC__Installed_Product__c WHERE Product_Code__c IN:productCode AND SVMXC__Status__c = \'Shipped\' AND Operation_Status__c != \'On\' AND Acceptance_Date__c = NULL AND SVMXC__Date_Installed__c = NULL AND  SVMXC__Date_Shipped__c<:dtDueDate';
        return Database.getQueryLocator(strQuery);
    }
    /*
    * Process the qualified records as batchs
    */
    public void execute(Database.BatchableContext bc, List<SVMXC__Installed_Product__c> lstIP){
        set<Id> setAccId  = new set<Id>();
        map<id, ObjectTerritory2Association> mapIPobjTerritory = new map<id,ObjectTerritory2Association>();
        List<SVMXC__Installed_Product__c> lstUpdatedIP = new List<SVMXC__Installed_Product__c>();
		
        for(SVMXC__Installed_Product__c objectIP : lstIP){
            setAccId.add(objectIP.SVMXC__Company__c);
        }
        List<ObjectTerritory2Association>listCPAccId = new ObjectTerritory2AssociationsSelector().selectIndirectByAccountIds(setAccId);
        for(ObjectTerritory2Association ota : listCPAccId){
            mapIPobjTerritory.put(ota.ObjectId, ota);
        }
        for(SVMXC__Installed_Product__c objIP : lstIP){
            Date dtStartDate = objIP.SVMXC__Date_Shipped__c;
            Date dtDueDate = Date.Today();
            Integer numberDaysDue = dtStartDate.daysBetween(dtDueDate);
            
            if((mapIPobjTerritory.containsKey(objIP.SVMXC__Company__c) && numberDaysDue>IP_UP_GRACE_PERIOD_CP) || !mapIPobjTerritory.containsKey(objIP.SVMXC__Company__c)){
                
                    objIP.Operation_Status__c = 'On';
                    objIP.SVMXC__Status__c = 'Installed';
                    objIP.Acceptance_Date__c = system.today();
                    objIP.SVMXC__Date_Installed__c = system.today();
                    lstUpdatedIP.add(objIP);
                
            }
        }
        
        if(!lstUpdatedIP.isEmpty()){
            Database.SaveResult[] result = Database.update(lstUpdatedIP, false);
            Integer intCount = 0;
            for (Integer i=0;i<result.size();i++){
                if(!result.get(i).isSuccess()){
                    for(Database.Error err : result.get(i).getErrors()){
                        setNonUpdatedIPErrors.add(lstIP.get(intCount).id +' : '+ err.getStatusCode() + ': ' + err.getMessage()+ ': ' + err.getFields());
                    }
                    lstSaveErrors.add(result.get(i));  
					mapRecIdToErrors.put(lstUpdatedIP.get(i).id, result.get(i).getErrors()[0].getMessage());
                }
                intCount++;
            }
        }
        
        
    }
    /*
    * Finish Method
    */
    public override void finish(Database.BatchableContext bc){
        if(!setNonUpdatedIPErrors.isEmpty() || !boolIsTestRunning){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new string[] {Label.SFDC_Service_Account_Email_Id});
            String subject = 'ACTION NEEDED: Installed Product (iSeq/Dragen) update failed';
            email.setSubject(subject);
            String strBody = 'Following Installed Prodcut were not updated : </br>';
            for(String str : setNonUpdatedIPErrors){
                strBody = strBody + str+'</br>';
			}
            email.setHtmlBody(strBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            boolEmailSent = true;
        }
		

		try{
			if (Feature.isOn('ServiceBatchErrorNotifications')){
				String source = 'BatchToUpdateIPiSeq';
				if(!lstSaveErrors.isEmpty()){
					ApexExceptions.emitSaveErrors(lstSaveErrors, source);
				}
				if(!mapRecIdToErrors.isEmpty()){
					ilib_Queueablethread  queueableThread=new ilib_Queueablethread('MSTeamsNotification'); 
					queueableThread.logandQueue(new QueueableMSTeamsNotificationSender(mapRecIdToErrors, source, batchProcessId),'QueueableMSTeamsNotificationSender','getTableEmailBodyAndSendNotification');		

					if(!queueableThread.lstQueueableJobs.isEmpty()){
						ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
					}						
				}
			}
		}
		catch(Exception e){
			System.debug('!!!!!!!!!!!!!'+e.getMessage());			
		}
		
    }
}