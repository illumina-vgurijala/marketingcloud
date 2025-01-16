/**
*    @author Dushyant Srivastava
*    @date   2nd December 
*    @description    DCP-51025 & DCP-51708: Cart Adding Product for Indirect 
*    @Test Class  -  TestUpdateProductPricingController
*    @ Test class Coverage: 88% - TestUpdateProductPricingController.cls
*    @ Test class Coverage: 75% - TestUpdateProductPricingController.cls
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Dushyant Srivastava           2021-12-02          Initial Version
*    ----------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class UpdateProductPricingController {
    public static final string STRSUCCESS = 'success';
    /**
	*  @author Dushyant Srivastava
	*  @description Method to check Record Access and get Updated Prices from SAP
	**/
    @AuraEnabled
    public static String checkRecordAccess(Id oppId) {
        try{
            String response = UpdatePricingOLIController.checkRecordAccess(oppId);
            if(response == STRSUCCESS) {
                response = UpdatePricingOLIController.getPricingDetails(oppId);
                return response;
            }
            return response;
        }
        catch(Exception e) { throw new AuraHandledException(e.getMessage()); }
    }
}