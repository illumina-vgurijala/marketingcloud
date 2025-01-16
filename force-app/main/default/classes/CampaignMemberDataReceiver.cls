/**
* @author Roopal Verma
* @date   2020-01-16
* @description    Campaign Member Synchronization to DCP
*
* Modification Log:
*       ------------------------------------------------------------------------------------
*       Roopal Verma        16/01/2020            Original Version 
*       ------------------------------------------------------------------------------------
*/@RestResource(urlMapping='/FreeTrialCreateInterface/*')
global with sharing class CampaignMemberDataReceiver extends ilib_RestReceiver {


    private static FreeTrialCreateWrapper.CampaignMemberWrapper campMemberWrapper;

    /**Method - Web Service method getting called from external Service */
    @Httppost
    global static void upsertIncomingValues()
    {
        // get the (non-static context) details
        CampaignMemberDataReceiver instantiated = new CampaignMemberDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);

        String strRestError = null;
        Id primaryRecordId;

        String strJsonInput = ((String.isNotBlank(RestContext.request.requestBody.toString())) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try
        {
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, campMemberWrapper);

            primaryRecordId = upsertIncomingValuesImpl();
        }
        
        catch (Exception e){
            strRestError = UtilsRest.handleCustomRestError(e);
        }
        
        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess)
        {
            UtilsRest.handleCustomRestSuccess();
        }

        ilib_LogInterface.finalizeLog(
                log,
                (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
                (isSuccess ? null : 'Exception: ' + strRestError),
                primaryRecordId
        );

        System.debug('log: '+ log);
 
        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, null, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
            /*
            ilib_LogEvent.quickEmit(
                    interfaceDetails.name + ' failed',
                    new Map<String, String> { 'Error Description' => strRestError }
            );*/
        }
        ilib_LogEvent.emit();
    }

    /**Method - Deserialize input to wrapper */
     global static void deserializeInputs(String jsonInput)
    {
        campMemberWrapper = (FreeTrialCreateWrapper.CampaignMemberWrapper) System.JSON.deserialize(jsonInput, FreeTrialCreateWrapper.CampaignMemberWrapper.class);
    }

    /**Method - Upsert values incoming from web service */
    private static Id upsertIncomingValuesImpl()
    {   

        Set<String> setPguidId = new Set<String>();
        Set<String> setZouraProdId = new Set<String>();

        FreeTrialCreateWrapper.CampaignMemberWrapper objCampMemberWrapper = campMemberWrapper;

        CampaignMember oneCampaignMember = objCampMemberWrapper.getSObject();         // assuming one Campaign Member record coming in

        setPguidId.add(objCampMemberWrapper.PGUID);
        setZouraProdId.add(objCampMemberWrapper.Zuora_Product_Id);
 
        List<Campaign> lstCampaign = new List<Campaign>(new CampaignSelector().selectCampaign(setZouraProdId));

        List<Contact> lstContact = new List<Contact>(new ContactsSelector().selectContactIdsforPGUIDId(setPguidId));

        if(!lstCampaign.isEmpty())
        oneCampaignMember.CampaignId = lstCampaign[0].Id;

        if(!lstContact.isEmpty())
            oneCampaignMember.ContactId = lstContact[0].Id;
        else {
            List<Lead> lstLead = new List<Lead>(new LeadsSelector().selectLeadsForPGUID(setPguidId));
            if(!lstLead.isEmpty())
            oneCampaignMember.LeadId = lstLead[0].Id;
        }

        Database.insert(oneCampaignMember);
        return (oneCampaignMember != null ? oneCampaignMember.Id : null);
    }
}