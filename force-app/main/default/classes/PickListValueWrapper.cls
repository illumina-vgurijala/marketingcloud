/**
*    @author Todd Newman  
*    @date   
*    @description Wapper class for picklist values
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Todd Newman                                         Initial Version
*             Himanshu                       31-03-2022         Code Scan Fixes
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*                    
**/
public with sharing class PickListValueWrapper {
    
    public String strKey,strValue;
    /**
	* @description parameterized constructor called
	* @params String strKey,String strValue
	* @return null
	**/
    public PickListValueWrapper (String strKey,String strValue) {
        this.strKey = strKey;
        this.strValue = strValue;
    }
    /**
	* @description parameterized constructor called
	* @params String strLabel
	* @return null
	**/
    public PickListValueWrapper(String strLabel){
        this.strKey = strLabel;
        this.strValue = strLabel;
    }

}