/**
*    @author Rishi Sharma
*    @date   2021-06-15
*    @description    SPQ-37: Last Marketing Campaign update on campaign members
*    @Test Class  -  
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Rishi                         2021-06-15	         Initial Version
*         Vaka Vishal Reddy             2022-08-22           CMSI-216 Instrumentation
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class CampaignMemberLastMarketingQueueable implements Queueable{

private static final String EXCEPTION_LOG_TITLE = 'CampaignMemberLastMarketingQueueable';
Map<id, List<CampaignMember>> mapCidToCm = new Map<id, List<CampaignMember>>();
public static Boolean catchException = false;

/*Paramterised Constructor */
public CampaignMemberLastMarketingQueueable( Map<id, List<CampaignMember>> mapCampIdtoMember) 
{
    this.mapCidToCm = mapCampIdtoMember;
   
}

/*Queueable execute method */
public void execute(QueueableContext qc) { 
    /*Getting the Campaign Id from the Map and updating the Last Marketing Campaign field with it*/
    ilib_LogEvent.setTitle(EXCEPTION_LOG_TITLE, ilib_LogEvent.MARKETING);
    ilib_LogEvent.push(EXCEPTION_LOG_TITLE+'.execute()');
    try
    {
      
        List<CampaignMember> lstFromMap = new List<CampaignMember>();
        List<CampaignMember> lstCmToUpdate = new List<CampaignMember>();
        id campId;
        
       for(Id cId: mapCidToCm.keySet()){
            lstFromMap = mapCidToCm.get(cId);
            campId = cId;
        }

       

        for(CampaignMember cm : lstFromMap){
            cm.Last_Marketing_Campaign__c = campId;
            lstCmToUpdate.add(cm);
        }
        
        ilib_LogEvent.info('lstCmToUpdate : '+UtilsCollection.getSetOfIds(lstCmToUpdate));
        update lstCmToUpdate;

        if(catchException == true){
            throw new AuraHandledException('throwing custom exceptions');
        }

	}
    catch(Exception e) { 
        ApexExceptions.emit(EXCEPTION_LOG_TITLE, e); 
        ilib_LogEvent.pop(); 
        ilib_LogEvent.emit();
    }
    ilib_LogEvent.pop();
    ilib_LogEvent.emit();
}



}