/**
 *    @author Vishal
 *    @date   19-Nov-2024
 *    @description  Class to send outbound messages for qualtrics survey
 *    @Test Class - TestIPOutboundMessageHandler
 * */
public with sharing class InstalledProductOutboundMessageHandler {
    
    public static final String INTERFACE_NAME_POST = 'Qualtrics_Survey_Direct';
    public static final String INTERFACE_NAME_POST_CP = 'Qualtrics_Survey_CP';
    /**
    hold http actions
    */ 
    public enum HttpMethod {HEAD, POST}
    public static final Integer SUCCESS = 200;
    public static final Integer ACCEPTED = 202;

     /**
     *  @author  Vishal
     *  @description This method is invoke by Installed Product Self Install Survey: Qualtrics Flow
     *  @return Void
     */
    @InvocableMethod(label='Send Data Through Outbound Message' description='Sends the outbound message' category='SVMXC__Installed_Product__c')
    public static void sendMessage(List<CheckPartner> installProductIdList) {
        if (installProductIdList == null || installProductIdList.isEmpty()) {
            return; // No IDs to process
        }
        sendOutboundMessages(installProductIdList[0].recordId, installProductIdList[0].isCP);
    }
     /**
     *  @author  Vishal
     *  @description This method is used to send outbound message to qualtrics
     *  @return Void
     */
    @future(callout=true)
    public static void sendOutboundMessages(Id recordId, Boolean isCP) {
        if (recordId == null) {
            return; // No records to process
        }
        
        try             
        {
            String interfaceName;
            if(isCP){
                 interfaceName = INTERFACE_NAME_POST_CP;
            }else{
                 interfaceName = INTERFACE_NAME_POST;
            }
            List<SVMXC__Installed_Product__c> updatedProducts = new List<SVMXC__Installed_Product__c>();
            
            SVMXC__Installed_Product__c installedProductRecord = new InstalledProductsSelector().getIP(recordId);
                try {
                    Map<String, Object> payload = createPayload(installedProductRecord);
                    String jsonPayload = JSON.serialize(payload);
                    
                    HttpRequest request = UtilsRest.createHttpRequestIP(interfaceName, HttpMethod.POST.name(), jsonPayload);
                    
                    HttpResponse response = UtilsRest.send(request);
                    
                    if (response.getStatusCode() == SUCCESS || response.getStatusCode() == ACCEPTED) {
                        installedProductRecord.Sent_to_Qualtrics__c = true;
                        updatedProducts.add(installedProductRecord);
                    }
                    System.debug('Response for Record ' + installedProductRecord.Id + ': Status=' + response.getStatusCode() + ', Body=' + response.getBody());
                } catch (Exception e) {
                    System.debug('HTTP Callout Error for Record ' + installedProductRecord.Id + ': ' + e.getMessage());
                }
            
            // Update only the products successfully sent
            if (!updatedProducts.isEmpty()) {
                update updatedProducts;
            }
        } catch (Exception e) {
            System.debug('Error in sendOutboundMessages: ' + e.getMessage());
        }
    }
     /**
     *  @author  Vishal
     *  @description Create payload for outbound message
     *  @return Map<String, Object> createPayload
     */
    private static Map<String, Object> createPayload(SVMXC__Installed_Product__c ipRecord) {
        return new Map<String, Object>{
            'InstalledProductId' => ipRecord.Id,
            'SVMXC__Serial_Lot_Number__c' => ipRecord.SVMXC__Serial_Lot_Number__c,
            'Account_Country__c' => ipRecord.Account_Country__c,
            'ProductId' => ipRecord.SVMXC__Product__r.Id,
            'ProductName' => ipRecord.SVMXC__Product__r.Name,
            'Product_Category__c' => ipRecord.Product_Category__c,
            'Product_Group__c' => ipRecord.Product_Group__c,
            'Product_Regulatory_Type__c' => ipRecord.Product_Regulatory_Type__c,
            'Region__c' => ipRecord.Region__c,
            'SVMXC__Company__c' => ipRecord.SVMXC__Company__r.Name,
            'ERP_Customer_Id__c' => ipRecord.SVMXC__Company__r.ERP_Customer_Id__c,
            'ContactRecordId' => ipRecord.SVMXC__Contact__c,
            'ContactEmail' => ipRecord.SVMXC__Contact__r.Email,
            'ContactFirstName' => ipRecord.SVMXC__Contact__r.FirstName,
            'ContactLastName' => ipRecord.SVMXC__Contact__r.LastName,
            'ContactFullName' => ipRecord.SVMXC__Contact__r.Name,
            'ContactPreferredLanguage' => ipRecord.SVMXC__Contact__r.Preferred_Language__c, 
            'SVMXC__Date_Shipped__c' => ipRecord.SVMXC__Date_Shipped__c
        };
    }
    /**
     *  @author  Vishal
     *  @description Invocable variables
     *  @return Void
     */
    public class CheckPartner {
        @InvocableVariable(required=true)
        public boolean isCP;
        @InvocableVariable(required=true)
        public Id recordId;
    }

}