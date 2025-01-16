/***************************************************************************************************************************************
* NAME   : COMM_Controller_UT 
* DESCRIPTION  : Test class for COMM_Controller_UT class
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class COMM_Controller_UT {

	static testmethod void commControllerTest() {
	
		ApexPages.StandardController controller = new ApexPages.StandardController(new Account());
		COMM_Controller objCOMMController = new COMM_Controller(controller);
		objCOMMController.CreateActivity();
		objCOMMController.CreateServicePricebook();
		objCOMMController.CreateService();
		objCOMMController.CreateServiceCatalog();		
		objCOMMController.CreateWorkTemplate();
		objCOMMController.CreatePMPlanTemplate();		
	}
}