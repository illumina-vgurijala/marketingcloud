/**
*    @author: Pankaj Singla
*    @date:   25-Nov-2019
*    @description:  REST Receiver for DMP Syc Data for Segments
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla              25 Nov 2019           Initial Build
              
*    ------------------------------------------------------------------------------------ 
*                    
*/ 
@RestResource(urlMapping='/dmpsegmentsync/*')
global with sharing class DMPSegmentReceiver extends ilib_RestReceiver {
    
    /**
    *  @author Pankaj Singla
    *  @description Receives the input JSON from SNAP and processes to call batch job
    *  @param 
    *  @return void
    **/
    
    @HttpPost
     global static void processIncomingJson(){
         String strRestError = null;
         DMPSegmentReceiver  instantiated = new DMPSegmentReceiver();
         ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
         ilib_LogEvent.setTitle(interfaceDetails.name);
         RestRequest     request    = RestContext.request;
         RestResponse    response   = RestContext.response;    
         response.addHeader('Content-Type','applicatin/json');
         String strJsonInput = ((null != RestContext.request.requestBody) ? (RestContext.request.requestBody.toString()) : (null));
         System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);
         
         ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, strJsonInput);
         try{
            
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');
            
            
            /*Call batch class to process the segments*/            
            Database.executebatch(new ProcessSegmentData(),200);
         }
          catch (Exception e){
              strRestError = UtilsRest.handleCustomRestError(e);
              system.debug('----->....>'+e);
          }
          Boolean isSuccess = String.isBlank(strRestError);
          if (isSuccess){
              UtilsRest.handleCustomRestSuccess();
          }
          
        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError)
            
        );
        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, log.logRecordId, log.logRecordId, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('processIncomingJson');
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


}