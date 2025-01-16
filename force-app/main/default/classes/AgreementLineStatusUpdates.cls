    /*
    *  @Author: Todd Newman
    *  @Date: 
    *  @Description: Class which contains implementations related to Agreement_Line_Status_Update__e
    *  90% code coverage : TestAgreementOutputParametersForm, TestApprovalsAgreementLineDiscount, TestApprovalsAgreementLineMaterialGroup, TestApprovalsAgreemetLineMaterialNumber, TestApttusAgreements
    *  75% code coverage : TestAgreementOutputParametersForm, TestApprovalsAgreementLineDiscount, TestApprovalsAgreementLineMaterialGroup, TestApprovalsAgreemetLineMaterialNumber, TestApttusAgreements
    *    Modification Log:
    *    ---------------------------------------------------------------------------------------------------------------------------
    *         Developer                      Date                Description         
    *         Todd Newman                                      Initial Version
    *         Nesar Mohan                 2022-03-30           CodeScan Fix 
    *         Biswajeet Sahoo             2022-09-05           [CMSI-211] Instrumentation of Classes
    *         Jitesh Lakhwani             2023-01-09           CodeScan fix
    *    ---------------------------------------------------------------------------------------------------------------------------
    **/

public with sharing class AgreementLineStatusUpdates extends ilib_SObjectDomain {

    public static final String LOG_TITLE = 'AgreementLineStatusUpdates';
    
    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_ONE = 1;
    //End CodeScan Fix

    /*
    *  @Author      : Todd Newman
    *  @Description : Constructor to pass the object list and initialize the variable
    *  @Param       : List<Agreement_Line_Status_Update__e>
    */

    public AgreementLineStatusUpdates(List<Agreement_Line_Status_Update__e> sObjectList) {
        super(sObjectList);
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);        //CMSI-211
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Boilerplate which is required for base class instantiation logic
    */

    public class Constructor implements ilib_SObjectDomain.IConstructable {

        /*
        *  @Author      : Todd Newman
        *  @Description : Constructor
        */
        public ilib_SObjectDomain construct(List<Agreement_Line_Status_Update__e> sObjectList) {
            return new AgreementLineStatusUpdates(sObjectList);
        }
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to execute in the Trigger after context
    *  @Param       : None
    *  @Return      : Void
    */
    public override void onAfterInsert()
    {
        // process first record
        Agreement_Line_Status_Update__e updateDetails = (Agreement_Line_Status_Update__e)records.get(0);
        ilib_LogEvent.info('Agreement where line statuses will be updated: ' + updateDetails);         //CMSI-211

        ApttusAgreementLineItemsService.updateStatusToMatchHeader(updateDetails.Agreement_ID__c, updateDetails.Agreement_Status__c);

        // NOTE : only deal with one at a time to avoid flooding the flex queue
        if (records.size() > INTEGER_ONE)
        {
            ilib_LogEvent.info('Stopping with one agreement in this execution, remaining agreements: ' +(records.size() - 1));
            EventBus.TriggerContext.currentContext().setResumeCheckpoint(updateDetails.replayId);
        }
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : utility method to publish, so this can be controlled in one place
    *  @Param       : Map<Id, String>
    *  @Return      : List<Database.SaveResult>
    */
    public static List<Database.SaveResult> publish(Map<Id, String> idToAgreementStatus)
    {
        ilib_LogEvent.push(LOG_TITLE+'.publish()');                     //CMSI-211
        List<Agreement_Line_Status_Update__e> lstEvents = buildEvents(idToAgreementStatus);
        ilib_LogEvent.info('idToAgreementStatus :'+(!idToAgreementStatus.isEmpty()?String.valueOf(idToAgreementStatus.keySet()): 'map is empty'));   //CMSI-211
        ilib_LogEvent.pop();                                            //CMSI-211
        return EventBus.publish(lstEvents);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to publish event so agreement line item statuses will be updated
    *  @Param       : Map<Id, String>
    *  @Return      : List<Agreement_Line_Status_Update__e>
    */
    public static List<Agreement_Line_Status_Update__e> buildEvents(Map<Id, String> idToAgreementStatus)
    {
        ilib_LogEvent.push(LOG_TITLE+'.buildEvents()');  //CMSI-211
        List<Agreement_Line_Status_Update__e> lstEvents = new List<Agreement_Line_Status_Update__e>();
        for (Id agreementId : idToAgreementStatus.keySet())
        {
            Agreement_Line_Status_Update__e e = new Agreement_Line_Status_Update__e(Agreement_ID__c = agreementId, Agreement_Status__c = idToAgreementStatus.get(agreementId));
            ilib_LogEvent.message('Publishing event so agreement line item statuses will be updated: ' + e); 
            lstEvents.add(e);
        }
        
        ilib_LogEvent.pop();           //CMSI-211
        return lstEvents;
    }

}