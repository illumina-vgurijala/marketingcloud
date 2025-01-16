    /*
    *  @Author: Kushagra Desai
    *  @Date: 
    *  @Description: Class for Apttus Cart Error page controller
    *  Modification Log:
    *  ---------------------------------------------------------------------------------------------------------------------------
    *       Developer                      Date                Description         
    *       Kushagra Desai                                   Initial Version
    *       Nesar Mohan                 2022-03-30           CodeScan Fix - Add code comments
    *    ---------------------------------------------------------------------------------------------------------------------------
    **/
public with sharing class ApttusCartErrorPageController {
	
	public String strErrors{get;set;}
	public Id strCartId{get;set;}
	public List<Apttus_Config2__ProductConfiguration__c> lstConfiguration;
	/*
    *  @Author      : Kushagra Desai
    *  @Description : Constructor of the class to retrieve CartId and corresponding configurations from the URL
    */
	public ApttusCartErrorPageController() {
		
		strCartId = (Id) ApexPages.CurrentPage().getParameters().get('id');
		lstConfiguration = new ApttusProductConfigurationsSelector().selectProductConfigurationById(strCartId);
		if(!lstConfiguration.isEmpty()){
			strErrors = lstConfiguration[0].SAP_errors__c;
		}
	}
}