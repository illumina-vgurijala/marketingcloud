/***************************************************************************************************************************************
* NAME         : EtQResponseWrapper
* DESCRIPTION  : This wrapper class holds the variable which comes back in response after integration callout is made.                   
* @AUTHOR      : Gladis
* @DATE        : 04-Apr-2022
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Gladis Evangaly        04-Apr-2022         QACM-15: Initial Version
****************************************************************************************************************************************/
public with sharing class EtQResponseWrapper {

	public String StatusCode; //response status code
	public String Messages; //response message
	public String ETQNumber; // response ETQ number
	public String QINumber;
	public String actualurl;
	public Integer DocumentId;
	public String ProblemTitle;

	
	//Contructor added for code coverage
	public EtQResponseWrapper(){}
	
}