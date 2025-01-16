/**
* @author : Todd Newman
* @date  :
* @description : Class containing utility methods for sharing Customer_Readiness_Form__c records 
* NOTE: is without sharing because addSharingToUsers() and removeSharingFromUsers() require it to work properly
* Test Classes for 75%: TestBatchMigrateShares, TestSharingConsole, TestTAPS_CustomerReadinessForm
* Test Classes for 90%: TestBatchMigrateShares, TestSharingConsole, TestTAPS_CustomerReadinessForm
* Modification Log:
*       ------------------------------------------------------------------------------------
*        Developer             Date                 Description
*       Todd Newman                                Initial Version
*       Aman Tyagi           30/03/2022            CodeScan Fixes
*       ------------------------------------------------------------------------------------
*/
public without sharing class CustomerReadinessFormsService {
    private static final String LOG_TITLE = 'CustomerReadinessFormsService';
    public static final String NULLSTR = 'Null';
    
    private static Customer_Readiness_Form__Share createSharingRecord(Id userId, Id recordId)
    {
        Customer_Readiness_Form__Share share = new Customer_Readiness_Form__Share(
            UserOrGroupId = userId,
            AccessLevel = 'Edit',
            ParentId = recordId,
            RowCause = Schema.Customer_Readiness_Form__Share.RowCause.Field_Users__c
        );
        ilib_LogEvent.message('Share : '+share);
        return share;
    }

    @TestVisible 
    private static void documentDmlError(SObject objShare, List<Database.Error> errors)
    {
        ilib_LogEvent.setTitle('CRF: sharing record DML error for '+objShare,ilib_LogEvent.SERVICE);
        String allErrorsString = '';
        for (Database.Error e : errors)
            allErrorsString += e.getMessage() + '\n\n';
            
        ilib_LogEvent.push('documentDmlError');
        ilib_LogEvent.error('Error Description' + allErrorsString +'----');
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
   }

    /*
    * @Author: Todd Newman
    * @Description : static method with logic of adding Apex sharing to the users
    * @param: Map<Id, Set<Id>> crfIdToUserIds
    * @return: void
    */
    public static void addSharingToUsers(Map<Id, Set<Id>> crfIdToUserIds)
    {
        ilib_LogEvent.push(LOG_TITLE+'addSharingToUsers()');
        if (crfIdToUserIds.size() == 0){
            ilib_LogEvent.pop();
            return;
        } 

        List<Customer_Readiness_Form__Share> shares = new List<Customer_Readiness_Form__Share>();
        for (Id crfId : crfIdToUserIds.keySet())
        {
            for (Id userId : crfIdToUserIds.get(crfId))
                shares.add(createSharingRecord(userId, crfId));
        }
        ilib_LogEvent.info('shares : '+UtilsCollection.getSetOfIds(shares));
        List<Database.SaveResult> allResults = Database.insert(shares, false);
        for (Integer i = 0; i < allResults.size(); i++)
        {
            Database.SaveResult res = allResults.get(i);
            if (!res.isSuccess())
                documentDmlError(shares.get(i), res.getErrors());
            else{
                System.debug('CRF share inserted successfully for ' + shares.get(i));
                ilib_LogEvent.message('CRF share inserted successfully for ' + shares.get(i));
            }
        }
        ilib_LogEvent.pop();
    }

    /*
    * @Author: Todd Newman
    * @Description : static method with logic of removing Apex sharing from the users
    * @param: Map<Id, Set<Id>> crfIdToUserIds
    * @return: void
    */
    public static void removeSharingFromUsers(Map<Id, Set<Id>> crfIdToUserIds)
    {
        ilib_LogEvent.push(LOG_TITLE+'removeSharingFromUsers()');
        List<Customer_Readiness_Form__Share> extantShareRecords =
            [SELECT Id, ParentId, UserOrGroupId
             FROM Customer_Readiness_Form__Share
             WHERE ParentId IN :crfIdToUserIds.keySet()
             AND RowCause = :Schema.Customer_Readiness_Form__Share.RowCause.Field_Users__c];
        ilib_LogEvent.info('extantShareRecords : '+UtilsCollection.getSetOfIds(extantShareRecords));
        // filter to make sure we only delete the records that match the input map
        for (Integer i = extantShareRecords.size() - 1; i >= 0; i--)
        {
            Customer_Readiness_Form__Share share = extantShareRecords.get(i);

            Id crfId = share.ParentId;
            ilib_LogEvent.message('crfId : '+crfId);
            if (!crfIdToUserIds.containsKey(crfId))
            {
                extantShareRecords.remove(i);
                continue;
            }

            Set<Id> userIds = crfIdToUserIds.get(crfId);
            ilib_LogEvent.message('userIds : '+userIds);
            if (!userIds.contains(share.UserOrGroupId))
                extantShareRecords.remove(i);
        }

        List<Database.DeleteResult> allResults = Database.delete(extantShareRecords, false);
        for (Integer i = 0; i < allResults.size(); i++)
        {
            Database.DeleteResult res = allResults.get(i);
            if (!res.isSuccess())
                documentDmlError(extantShareRecords.get(i), res.getErrors());
            else{
                System.debug('CRF share deleted successfully for ' + extantShareRecords.get(i));
                ilib_LogEvent.message('CRF share deleted successfully for ' + extantShareRecords.get(i));
            }
        }
        ilib_LogEvent.pop();
    }

    private static Map<Id, Set<Id>> getOppIdToUserIds(List <Customer_Readiness_Form__c> newCrfs, Map<Id, Customer_Readiness_Form__c> idToOldCrfs)
    {
        ilib_LogEvent.push(LOG_TITLE+'getOppIdToUserIds()');
        Map<Id, Set<Id>> oppIdToUserIds = new Map<Id, Set<Id>>();

        Set<Id> oppIds = UtilsCollection.getSetOfIds(newCrfs, 'Opportunity_Name__c');
        if (idToOldCrfs != null)
            oppIds.addAll(UtilsCollection.getSetOfIds(idToOldCrfs.values(), 'Opportunity_Name__c'));

        ilib_LogEvent.info('oppIds : '+oppIds);
        if (oppIds.isEmpty()){
            ilib_LogEvent.pop();
            return oppIdToUserIds;
        }
        List<Opportunity> fieldUserDetails =
            [SELECT Id, Primary_Field_Service_Engineer__c, Primary_Field_Application_Scientist__c,
                    Field_Application_Manager__c, Field_Service_Manager__c,
                    Partner_Primary_Field_App_Scientist__c, Partner_Primary_Field_Service_Engineer__c
             FROM Opportunity
             WHERE Id IN :oppIds];

        for (Opportunity opp : fieldUserDetails)
        {
            Set<Id> userIds = new Set<Id>();
            if (opp.Primary_Field_Service_Engineer__c != null) userIds.add(opp.Primary_Field_Service_Engineer__c);
            if (opp.Primary_Field_Application_Scientist__c != null) userIds.add(opp.Primary_Field_Application_Scientist__c);
            if (opp.Field_Application_Manager__c != null) userIds.add(opp.Field_Application_Manager__c);
            if (opp.Field_Service_Manager__c != null) userIds.add(opp.Field_Service_Manager__c);
            ilib_LogEvent.message('userIds : '+userIds);
            if (!userIds.isEmpty())
                oppIdToUserIds.put(opp.Id, userIds);
        }
        ilib_LogEvent.info('oppIdToUserIds : '+oppIdToUserIds);
        ilib_LogEvent.pop();
        return oppIdToUserIds;
    }

    /*
    * @Author: Todd Newman
    * @Description : static method with logic  for Aoex sharing for field users
    * @param: List <Customer_Readiness_Form__c> newCrfs, Map<Id, Customer_Readiness_Form__c> idToOldCrfs
    * @return: void
    */
    public static void shareWithFieldUsers(List <Customer_Readiness_Form__c> newCrfs, Map<Id, Customer_Readiness_Form__c> idToOldCrfs)
    {
        ilib_LogEvent.push(LOG_TITLE+'shareWithFieldUsers()');
        ilib_LogEvent.info('newCrfs : '+UtilsCollection.getSetOfIds(newCrfs));
        ilib_LogEvent.info('idToOldCrfs : ' +  (idToOldCrfs != Null ? String.valueof(idToOldCrfs.keySet()):NULLSTR));
        Map<Id, Set<Id>> oppIdToUserIds = getOppIdToUserIds(newCrfs, idToOldCrfs);

        Map<Id, Set<Id>> crfIdToAddedUserIds = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> crfIdToRemovedUserIds = new Map<Id, Set<Id>>();

        if (idToOldCrfs == null)
        {
            // insert operation, add all opp->crf
            for (Customer_Readiness_Form__c crf : newCrfs)
            {
                Id newOppId = crf.Opportunity_Name__c;
                ilib_LogEvent.message('newOppId : '+newOppId);
                if (newOppId != null && oppIdToUserIds.containsKey(newOppId))
                {
                    crfIdToAddedUserIds.put(crf.Id, oppIdToUserIds.get(newOppId));
                }
            }
        }
        else
        {
            // update, add only if opp ID changed
            for (Customer_Readiness_Form__c crf : newCrfs)
            {
                Id newOppId = crf.Opportunity_Name__c;
                Id oldOppId = idToOldCrfs.get(crf.Id).Opportunity_Name__c;
                ilib_LogEvent.message('newOppId : '+newOppId);
                ilib_LogEvent.message('oldOppId : '+oldOppId);
                if (newOppId != oldOppId)
                {
                    if (newOppId != null && oppIdToUserIds.containsKey(newOppId))
                    {
                        crfIdToAddedUserIds.put(crf.Id, oppIdToUserIds.get(newOppId));
                    }
                    if (oldOppId != null && oppIdToUserIds.containsKey(oldOppId))
                    {
                        crfIdToRemovedUserIds.put(crf.Id, oppIdToUserIds.get(oldOppId));
                    }
                }
            }
        }

        if (!crfIdToRemovedUserIds.isEmpty())
        {
            ilib_LogEvent.info('crfIdToRemovedUserIds : ' +  (crfIdToRemovedUserIds != Null ? String.valueof(crfIdToRemovedUserIds.keySet()):NULLSTR));
            System.debug('Field User Sharing: crfIdToRemovedUserIds ' + crfIdToRemovedUserIds);
            removeSharingFromUsers(crfIdToRemovedUserIds);
        }

        if (!crfIdToAddedUserIds.isEmpty())
        {
            ilib_LogEvent.info('crfIdToAddedUserIds : ' +  (crfIdToAddedUserIds != Null ? String.valueof(crfIdToAddedUserIds.keySet()):NULLSTR));
            System.debug('Field User Sharing: crfIdToAddedUserIds ' + crfIdToAddedUserIds);
            addSharingToUsers(crfIdToAddedUserIds);
        }
        ilib_LogEvent.pop();
    }

}