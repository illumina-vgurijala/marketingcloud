/**
 *   @author: Rajbabu Boopalan
*    @date:   11-Mar-2024
*    @description: Queueable class to emit platform event
*    @Test Class: 
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*        Developer           Date                Description
*        Rajbabu Boopalan    11-Mar-2024         CMCM-5579: Initial build
*    --------------------------------------------------------------------------------------------------
 */
public with sharing class Ilib_LogEvent_PlatformEventEmitQueueable implements Queueable {
    public static final String LOG_TITLE = 'Ilib_LogEvent_PlatformEventEmitQueueable';
    private List<ilib_LogEvent.publishParameter> lstPublishParameters =new List<ilib_LogEvent.publishParameter>();      

    /**
     * @author: Rajbabu Boopalan
     * @date: 11-Mar-2024
     * @description: Constructor
     * @param: List<ilib_LogEvent.publishParameter> publishParameters
     * @return: NA
     */
    public Ilib_LogEvent_PlatformEventEmitQueueable(List<ilib_LogEvent.publishParameter> publishParameters) {
        if(!publishParameters.isEmpty()) {
            this.lstPublishParameters = publishParameters;
        }
    }
     /**
     * @author: Rajbabu Boopalan
     * @date: 11-Mar-2024
     * @description: Queueable execute method
     * @param: queue context
     * @return: void
     */
    public void execute(QueueableContext context) {
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try {
            ilib_LogEvent.info('lstPublishParameters size: ' + lstPublishParameters.size());
            ilib_LogEvent.message('lstPublishParameters json: ' + JSON.serializePretty(lstPublishParameters));
            if (!lstPublishParameters.isEmpty()) {
                // publish the platform event
                IlmnLogs.publishList(lstPublishParameters);
                ilib_LogEvent.pop();
            }
        } catch(Exception ex) {
            ApexExceptions.emit(LOG_TITLE+'.execute-publishParameter-' + lstPublishParameters, ex);
            throw ex;
        }
        ilib_LogEvent.emit();
    }
}