/***************************************************************************************************************************************
* NAME         : LokaliseTranslationRequestWrapper
* DESCRIPTION  : DCP-56433 Request Wrapper class for Lokalise Translation API
* @AUTHOR      : Sagar Madkaikar
* @DATE        : 14-Sep-2022 
* @Testclass   : TestWOTranslationDataSender
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Sagar Madkaikar        14-Sep-2022         DCP-56433 : Initial Version
* --------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/

public with sharing class LokaliseTranslationRequestWrapper {
    
    public List<Keys> keys;
	public Boolean use_automations;

	/**
    *  @AUTHOR Sagar 
    *  @DESCRIPTION - Keys class
    **/
    public class Keys {
		public List<String> platforms;
		public List<Translations> translations;
		public String key_name;
		public String description;
		public String key_id;
	}

	/**
    *  @AUTHOR Sagar 
    *  @DESCRIPTION - Translations class
    **/
	public class Translations {
		public String language_iso;
		public String translation;
	}

	
}
