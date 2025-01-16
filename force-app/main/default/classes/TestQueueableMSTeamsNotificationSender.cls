/**
*    @author : Nitin Sood
*    @date   : 15-7-2021
*    @description : Test class for QueueableMSTeamsNotificationSender.
*    Modification Log:
*    ------------------------------------------------------------------------------------ 

*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest(SeeAllData=false)
public class TestQueueableMSTeamsNotificationSender {        

/**
*    @author : Nitin Sood
*    @date   : 15-7-2021
*/
    static testmethod void testMethod1() {
        Test.startTest();
        Map<Id, String> mapRecIdToErrors = new Map<Id, String>();
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        insert objInstalledProduct;
		System.assert(objInstalledProduct.Id != null);
        
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location','Test Street','Ireland','123456','USD');
        insert objLocation;
        System.assert(objLocation.Id != null);
		
        Case objCase = TestDataCase.initNewCase('Business Issue', 'Initiated', 'Phone - CS');
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.SVMXC__Site__c = objLocation.Id;  
        objCase.Date_of_Issue_Awareness__c = Date.Today();      
        insert objCase;
		System.assert(objCase.Id != null);
		
        mapRecIdToErrors.put(objCase.id, 'Error');
        ilib_Queueablethread  queueableThread=new ilib_Queueablethread('MSTeamsNotification'); 
        queueableThread.logandQueue(new QueueableMSTeamsNotificationSender(mapRecIdToErrors, 'TestClass', null),'QueueableMSTeamsNotificationSender','getTableEmailBodyAndSendNotification');       
		System.Assert(!queueableThread.lstQueueableJobs.isEmpty());
        if(!queueableThread.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(queueableThread);
        }
        Test.stopTest();
		
    }
	/*Test method to cover Catch Block of Class QueueableMSTeamsNotificationSender
	*/
   static testmethod void coverCatchBlockQueueableMSTeamsNotificationSender(){
    try{
        QueueableMSTeamsNotificationSender.catchException = true;
        QueueableMSTeamsNotificationSender qm = new QueueableMSTeamsNotificationSender(null, null, null);
        Test.startTest();
        System.enqueueJob(qm);
        Test.stopTest();
    	}catch(Exception e){
            System.assert(e!=null, 'e is not empty');
    	}
   }
                    
}