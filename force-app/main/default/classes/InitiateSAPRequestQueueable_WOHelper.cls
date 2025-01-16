/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger to initiate SAP request
*/ 
public class InitiateSAPRequestQueueable_WOHelper implements Queueable {

    Set<Id> setWOforPricingRequest = new Set<Id>();
    private static final String LOG_TITLE = 'InitiateSAPRequestQueueable_WOHelper';
 
     /*******************************************************************************************************
     * @description Constructor
     * @param setWOforPricingRequest Set<Id>
     * @return
     */
     public InitiateSAPRequestQueueable_WOHelper(Set<Id> setWOforPricingRequest) {
         this.setWOforPricingRequest = setWOforPricingRequest;
     }
 
     /*******************************************************************************************************
     * @description Execute method
     * @param QueueableContext qc
     * @return
     */
     public void execute(QueueableContext qc) { 
         ilib_LogEvent.push(LOG_TITLE + '.execute()');
         try {
             initiateRequesttoSAP(setWOforPricingRequest);
         } catch(Exception ex) {
             ApexExceptions.emit('InitiateSAPRequestQueueable_WOHelper.'+ 'initiateRequesttoSAP', ex);
             throw ex;
         }
         ilib_LogEvent.pop();
     }
 
     /*DCP-38806
     * method :initiateRequesttoSAP
     * params : set<Id> setWOforPricingRequest
     * Author: Digvijay
     * return: void
     */
     public static void initiateRequesttoSAP(set<id> setWOforPricingRequest) {
         
         List<Id> listwdId = new List<Id>();
         
         for(SVMXC__Service_Order_Line__c obj : new WorkDetailsSelector().selectWorkDetailsForWorkOrderId(setWOforPricingRequest)) {
             if(obj.SVMXC__Product__c!=null && obj.SVMXC__Line_Status__c!= WorkOrders.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
                 listwdId.add(obj.id);
             }
         }
         
         if(!listwdId.IsEmpty()) { 
             ServicePriceListDataSender objsender = new ServicePriceListDataSender();
             List<GetPricingDetails.AccountInfoWrapper> listaccountInfoWrapper = GetPricingDetails.getAccountAndPricingDetails(listwdId);
             ilib_LogEvent.message('listaccountInfoWrapper: '+listaccountInfoWrapper);
             
             for(GetPricingDetails.AccountInfoWrapper wrapObj : listaccountInfoWrapper) {
                 Map<Id, GetPricingDetails.AccountInfoWrapper> mapworkOrdertoAccountInfo=new  Map<Id, GetPricingDetails.AccountInfoWrapper>();
                 mapworkOrdertoAccountInfo.put(wrapObj.key,wrapObj); 
                 ilib_LogEvent.message('mapworkOrdertoAccountInfo: '+mapworkOrdertoAccountInfo);
                 if(!Test.isRunningTest()) {
                     objsender.callout(mapworkOrdertoAccountInfo);
                 }
             }
         }
     }
 
 
 }
 
 