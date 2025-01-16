/***************************************************************************************************************************************
 * NAME         : PromotionDataReceiver
 * DESCRIPTION  : Promotion Data Synchronization 
 * @AUTHOR      : Karthik Rayani
 * @DATE        : 08-Sep-2020   
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 *  Karthik Rayani		08-Sep-2020 			DCP-40228-Initial Version.
 ****************************************************************************************************************************************/

@RestResource(urlMapping = '/PromoSyncInterface/')
global with sharing class PromotionDataReceiver extends ilib_RestReceiver {

    // Inputs
    private static List < PromotionWrapper > lstWrapPromotionMasterList;

    /*
    * @author:Karthik
   */
    @HttpPost
    global static void upsertIncomingValues() 
    {
        String strRestError = null;
        Id primaryRecordId;
        PromotionDataReceiver instantiated = new PromotionDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);
        String strJsonInput = ((null != RestContext.request.requestBody) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, JSON.serializePretty(JSON.deserializeUntyped(strJsonInput)));
        try 
        {
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');
            deserializeInputs(strJsonInput);
            primaryRecordId = upsertIncomingValuesImpl();
        } 
        catch (Exception e) 
        {
            strRestError = UtilsRest.handleCustomRestError(e);
            system.debug('----->....>' + e);
        }
        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess) 
            UtilsRest.handleCustomRestSuccess();
        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );
        if (!isSuccess) {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, primaryRecordId, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
           /* ilib_LogEvent.quickEmit(
                interfaceDetails.name + ' failed',
                new Map < String, String > {
                    'Error Description' => strRestError
                }
            );*/
        }
        ilib_LogEvent.emit();
    }
    /*
    * @author:Karthik
   */
    global static void deserializeInputs(String jsonInput) {
        lstWrapPromotionMasterList = (List < PromotionWrapper > ) System.JSON.deserialize(jsonInput, List < PromotionWrapper > .class);
    }
    /*
    * @author:Karthik
   */
    global static Id upsertIncomingValuesImpl() 
    {
        Promotions__c onePromotion;
        // Register custom helpers
        ilib_UpsertHelpers.PromotionsUnitofWorkHelper promoWork = new ilib_UpsertHelpers.PromotionsUnitofWorkHelper();
        //Map ExternalId to Object 
        Map < String, PromotionWrapper > mapErpIdToPromotion = new Map < String, PromotionWrapper > ();
        //unit of work
        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(
            new List < Schema.SObjectType > {
                Promotions__c.SObjectType
            });
        uow.registerWork(promoWork);
        for (PromotionWrapper wrapPromotion: lstWrapPromotionMasterList)
            mapErpIdToPromotion.put(wrapPromotion.Promotion_Code, wrapPromotion);
        PromotionWrapper promoWrapper = new PromotionWrapper();
        List < Promotions__c > upsertRecords = new List < Promotions__c > ();
        // match account ERP IDs to existing  ERP ID values
        List < Promotions__c > existingPromoRecords = [SELECT Id, Promotion_Code__c FROM Promotions__c WHERE Promotion_Code__c IN: mapErpIdToPromotion.keySet()];
        for (Promotions__c objPromo: existingPromoRecords) 
        {
            onePromotion = objPromo;
            upsertRecords.add(promoWrapper.getSobject(mapErpIdToPromotion.get(objPromo.Promotion_Code__c)));
            mapErpIdToPromotion.remove(objPromo.Promotion_Code__c);

        }
        upsertRecords.addAll(promoWrapper.getSobjectList(mapErpIdToPromotion.values()));
        promoWork.registerUpsert(upsertRecords);
        uow.commitWork();
        return (onePromotion != null ? onePromotion.Id : null);
    }
}