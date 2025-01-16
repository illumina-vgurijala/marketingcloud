/***************************************************************************************************************************************
* NAME   : AutoCompleteController 
* DESCRIPTION  : Controller class
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class COMM_Controller
{
    
    SVMXC.COMM_Utils_ManageSettings objSettings = new SVMXC.COMM_Utils_ManageSettings();
    map<String, String> objCOMMSetts = new map<String, String>();
    private static Final String HTML = 'HTML5';
    
	/*
     * Constructor
     */
    public COMM_Controller(ApexPages.StandardController controller) 
    {
        try
        {
            objCOMMSetts = objSettings.SVMX_getSettingList('COMM003');
        }
        catch(Exception ex)
        { 
            ApexExceptions.emit('COMM_Controller',ex);
        }
    }
    
	/*
     * description - PageReference CreateActivity()
	 * Return - PageReference
     */
    public PageReference CreateActivity()
    {
        try
        {
            return RedirectTo('Activity_Master__c',(objCOMMSetts != null && objCOMMSetts.ContainsKey('SET001') && objCOMMSetts.get('SET001').length() > 0) ? objCOMMSetts.get('SET001') : 'SCON_CR_ActivitMaster');
        }catch(Exception ex)
        {
            throw ex;
        }
    }
    
	/*
     * description - PageReference CreateServicePricebook()
	 * Return - PageReference
     */
    public PageReference CreateServicePricebook()
    {
        return RedirectTo('Service_Pricebook__c',objCOMMSetts != null && objCOMMSetts.ContainsKey('SET002') && objCOMMSetts.get('SET002').length() > 0 ? objCOMMSetts.get('SET002') : 'SCON_CR_Pricebook');
    }
    
	/*
     * description - PageReference CreateService()
	 * Return - PageReference	 
     */
    public PageReference CreateService()
    {
        return RedirectTo('Service__c',objCOMMSetts != null && objCOMMSetts.ContainsKey('SET003') && objCOMMSetts.get('SET003').length() > 0 ? objCOMMSetts.get('SET003') : 'SCON_CR_Service');
    }
    
	/*
     * description - PageReference CreateServiceCatalog()
	 * Return - PageReference	 
     */
    public PageReference CreateServiceCatalog()
    {
        return RedirectTo('Service_Plan__c',objCOMMSetts != null && objCOMMSetts.ContainsKey('SET004') && objCOMMSetts.get('SET004').length() > 0 ? objCOMMSetts.get('SET004') : 'SCON_CR_ServicePlan');
    } 
    
	/*
     * description - PageReference CreateWorkTemplate()
	 * Return - PageReference
     */
	public PageReference CreateWorkTemplate()
    {
        return RedirectTo('SVMXC__Task_Template__c',objCOMMSetts != null && objCOMMSetts.ContainsKey('SET006') && objCOMMSetts.get('SET006').length() > 0 ? objCOMMSetts.get('SET006') : 'CR_WorkTemplate');
    } 
	
	/*
     * description - PageReference CreatePMPlanTemplate()
	 * Return - PageReference
     */
	public PageReference CreatePMPlanTemplate()
    {
        return RedirectTo('SVMXC__PM_Plan_Template__c',objCOMMSetts != null && objCOMMSetts.ContainsKey('SET007') && objCOMMSetts.get('SET007').length() > 0 ? objCOMMSetts.get('SET007') : 'CR_PMPlanTemplate');
    } 
	
	/*
     * description - PageReference RedirectTo()
	 * Return - PageReference
     */
    public PageReference RedirectTo(String strObjName, String strSFMProc)
    {
        map<String, Schema.SObjectType> objGlobalDescribe = new map<String, Schema.SObjectType>();
        String strObjectName = strObjName;
        String strKeyPrefix = '';
        objGlobalDescribe = Schema.getGlobalDescribe();
        
        if(!objGlobalDescribe.containsKey('SVMXC__' + strObjectName ))
        {
            //This is to work in base org
            if(objGlobalDescribe.containsKey(strObjectName ))
            {
                Schema.DescribeSObjectResult objSobjectDescribe = objGlobalDescribe.get(strObjectName).getDescribe();
                strKeyPrefix = objSobjectDescribe.getKeyPrefix();
            }
        }
        else
        {
            Schema.DescribeSObjectResult objSobjectDescribe = objGlobalDescribe.get('SVMXC__' + strObjectName).getDescribe();
            strKeyPrefix = objSobjectDescribe.getKeyPrefix();
        }
        PageReference objRedirect = new PageReference('/apex/'+getDeliveryPageName()+'?SVMX_processId=' + strSFMProc + '&SVMX_retURL=../' + strKeyPrefix);
        objRedirect.setRedirect(true);
        return objRedirect;
    }
	
	/*
     * description - retrning string 
     */
	public String getDeliveryPageName()
	{
		String strPageName = 'SVMXC__SFM_TDM_Delivery';
		try
        {
			map<String, String> svmxSettingList = objSettings.SVMX_getSettingList('GLOB001');
			if(svmxSettingList.containsKey('GBL021') && svmxSettingList.get('GBL021') != null )
			{
				if(svmxSettingList.get('GBL021').toUpperCase() == HTML)
					strPageName = 'SVMXC__ServiceMaxConsole';
			}
			return strPageName;
		}
		catch(Exception ex)
        {
			return strPageName;
		}
	}
}