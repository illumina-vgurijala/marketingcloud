/***************************************************************************************************************************************
* NAME   : PostRefreshActivities
* DESCRIPTION  : Class to schedule batches which masks the email address on contacts,leads,service contract and workorder records.It also deletes transactional data record
*       like exception logs, interfacelogs,charket logs, dupeblocker logs, and apex jobs
*
* @AUTHOR : Goutham Ramireddy (Release Team)
* @DATE   : 09-May-2021
*
* MODIFICATION LOG:
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION
* --------------------------------------------------------------------------------------------------------------------------------------
* Goutham                 20th July 2021        Initial Version
* Goutham                 25th March 2022       Making the class generic and introducing logic so that sObject fields and SOQL queries will be stored in custom metadata records

****************************************************************************************************************************************/
public with sharing class PostRefreshActivities implements SandboxPostCopy{

    public static final integer MASKBATCHSIZE = 100;
    public static final integer DELETEBATCHSIZE = 2000;

/***************************************************************************************************************************************
        *METHOD NAME   : runApexClass
        * DESCRIPTION  : This method calls the batches to schedule
        *
        * @DATE   : 09-May-2021
        *
****************************************************************************************************************************************/
    public void runApexClass(SandboxContext context)
    {    
        //Below method deleted all the existing jobs in queue which are not valid for a newly refreshed sandbox
        if(!Test.isRunningTest()){
            System.purgeOldAsyncJobs(date.today());
        }

        

        List<Post_Refresh_Cleanup__mdt> lstsObjects = Post_Refresh_Cleanup__mdt.getAll().values();
        
        if(!lstsObjects.isEmpty()){
        
            for(Post_Refresh_Cleanup__mdt sObj: lstsObjects){
            
                if(!sObj.Query_Delete__c){
                    //Below logic is to mask the emails with .invalid at the end
                
                    Set<String> fieldsToMask = new Set<String>(sObj.Email_Fields__c.split(','));
                
                    BatchBulkEmailMaskUpdate masksObjectFields= new BatchBulkEmailMaskUpdate(sObj.Query__c,fieldsToMask);
                    ilib_BatchManager.executebatch(masksObjectFields,MASKBATCHSIZE);
                }
                else{
                    //Below logic is to delete operational records data which is not valid in sandbox
                    
                    BatchBulkDeleteOperationalLogsData deleteOperationalLogs= new BatchBulkDeleteOperationalLogsData(sObj.Query__c);
                    ilib_BatchManager.executebatch(deleteOperationalLogs,DELETEBATCHSIZE);
                
                }
            }
        }
        

    }
   
}
