/***************************************************************************************************************************************
* NAME         : LokaliseTranslationResponseWrapper
* DESCRIPTION  : DCP-56433 Response Wrapper class for Lokalise Translation API
* @AUTHOR      : Sagar Madkaikar
* @DATE        : 14-Sep-2022 
* @Testclass   : TestWOTranslationDataSender
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Sagar Madkaikar        14-Sep-2022         DCP-56433 : Initial Version
* Rucha Dalvi			 17-Feb-2023		 TASK0871398 : changed data type to resolve Input String Issue
* --------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/
public class LokaliseTranslationResponseWrapper {

    public String project_id;
	public List<Keys> keys;
	public List<Errors> errors;
    
	/**
    *  @AUTHOR Sagar 
    *  @DESCRIPTION - Wrapper class
    **/
	public class Errors {
		public String message;
		public Integer code;
		public Key_name key_name;
	}

	/**
    *  @AUTHOR Sagar 
    *  @DESCRIPTION - Wrapper class
    **/
	public class Keys {
		public Integer key_id;
		public String created_at;
		public Integer created_at_timestamp;
		public Key_name key_name;
		public Key_name filenames;
		public String description;
		public List<String> platforms;
		public List<Translations> translations;
		public Boolean is_plural;
		public String plural_name;
		public Boolean is_hidden;
		public Boolean is_archived;
		public String context;
		public Integer base_words;
		public Integer char_limit;
		public String custom_attributes;
		public String modified_at;
		public Integer modified_at_timestamp;
		public String translations_modified_at;
		public Integer translations_modified_at_timestamp;
	}

	

	/**
    *  @AUTHOR Sagar 
    *  @DESCRIPTION - Wrapper class
    **/
	public class Key_name {
		public String ios;
		public String android;
		public String web;
		public String other;
	}

	/**
    *  @AUTHOR Sagar 
    *  @DESCRIPTION - Wrapper class
    **/
	public class Translations {
		public Decimal translation_id; //changed data type for TASK0871398
		public Integer segment_number;
		public Decimal key_id; //changed data type for TASK0871398
		public String language_iso;
		public String translation;
		public Integer modified_by;
		public String modified_by_email;
		public String modified_at;
		public Integer modified_at_timestamp;
		public Boolean is_reviewed;
		public Integer reviewed_by;
		public Boolean is_unverified;
		public Boolean is_fuzzy;
		public Integer words;
		public Object task_id;
	}

	
}