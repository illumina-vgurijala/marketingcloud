/**
*    @author: Joshith K
*    @date:   21-Sep-2019
*    @description:  Queuable class for sync orphan software records to Lead/Contact
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Joshith k                    21-Sep-2019        Initial Version
*            Aman Tyagi                   31-March-2022      Codescan Fixes
*            Satya Swain                  09 Dec 2022        Added Codescan fix for Variable Naming Convention
*    ------------------------------------------------------------------------------------ 
*/
public with sharing class SoftwareDownloadQueueableForSync implements Queueable {

    List<SObject> parentRecords;
	public static Boolean catchException = false;
    /*
    * @Author:  Joshith k    
    * @Description : parameterized constructor of class SoftwareDownloadQueueableForSync and instantiating Sobject
    * @param :List<Sobject> parentRecords
    */
    public SoftwareDownloadQueueableForSync(List<Sobject> parentRecords)
    {
        this.parentRecords=parentRecords;
    }

    /*
    * @Author:  Joshith k    
    * @Description : method to execute the queueable context
    * @param :QueueableContext context
    * @modification : CMSI-38 Added try catch mechanism and emitting exception to ApexExceptions with Workstream.
    * @return : void
    */
    public void execute(QueueableContext context)
    {
        try{
        List<ObjectPermissions> objPermissionList = [
            SELECT Id, SObjectType, PermissionsRead
            FROM ObjectPermissions
            WHERE ParentId IN (SELECT Id from PermissionSet WHERE PermissionSet.Profile.Id = :UserInfo.getProfileId())
            AND SobjectType = 'Software_Download__c'
        ];

        Boolean isObjectAccess = false;
        if (objPermissionList.size() > 0)
        {
            isObjectAccess = objPermissionList[0].PermissionsRead;
        }

        if (!isObjectAccess)
        {
            return;
        }

        Schema.SObjectType sObjectTypeVar;
        Schema.SObjectType contactType = Schema.Contact.getSObjectType();

        if (!parentRecords.isEmpty())
        {
            sObjectTypeVar = parentRecords[0].getSObjectType();
        }
        
        Map<String,Sobject> mapParentRecords = new Map<String,Sobject>();
        for (Sobject obj:parentRecords)
        {
            system.debug('email' + ((String)obj.get('email')).toLowerCase());
            mapParentRecords.put(((String)obj.get('email')).toLowerCase(), obj);
        }

        List<Software_Download__c> listToUpdate = new List<Software_Download__c>();
        for (Software_Download__c objSWD : new SoftwareDownloadsSelector().selectSoftwareDownloadByEmail(mapParentRecords.keySet()))
        {
            System.debug('swd rec'+objSWD);
            Sobject parent = mapParentRecords.get(objSWD.Email_Address__c);
            objSWD.Country__c = '';
            objSWD.First_Name__c = (String)parent.get('FirstName');
            objSWD.Last_Name__c = (String)parent.get('LastName');

            if (sObjectTypeVar == contactType)
            {
                objSWD.Contact_Full_Name__c = (Id)parent.get('Id');
                if (String.isNotBlank((String)parent.get('MailingCountry')))
                {
                    objSWD.Country__c = (String)parent.get('MailingCountry');                    
                }
            }
            else
            {
                System.debug('inside lead');
                objSWD.Lead_full_name__c = (Id)parent.get('Id');
                if(String.isNotBlank((String)parent.get('Country')))
                {
                    objSWD.Country__c = (String)parent.get('Country');
                }
            }

            if (String.isBlank(objSWD.Country__c))
                objSWD.Country__c = (String)parent.get('Country_Local__c');

            listToUpdate.add(objSWD);
        }

        if (!listToUpdate.isEmpty())
            update listToUpdate;
		if(catchException == true){
			throw new AuraHandledException('Throwing Custom Exception');
		}	
        }catch(Exception e){
            //CMSI-38 Emitting exception to ApexExceptions with Workstream.
            ApexExceptions.emit('SoftwareDownloadQueueableForSync',e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }
    }
    

}
