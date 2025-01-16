/**
 * This file needs a description 
 * @class com.servicemax.client.sfmopdocdelivery.constants
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	
	var constantsImpl = SVMX.Package("com.servicemax.client.sfmopdocdelivery.constants");

constantsImpl.init = function(){
	constantsImpl.Class("Constants", com.servicemax.client.lib.api.Object, {
		__constructor : function(){}
	}, {
		FINALIZE 							: "Finalize",
		FINALIZE_DIV 						: "finalize_div",
		DRAFT	 							: "Generate Draft",
		DRAFT_DIV	 						: "draft_div",	
		DOCUMENT_PAGE 						: "document_page",
		DOCUMENT_SPINNER 					: "document_spinner",
		TODAY								: "Today",
		TOMORROW							: "Tomorrow",
		YESTERDAY							: "Yesterday",
		NOW									: "Now",
		USERNAME							: "UserName",
		ADDRESS							    : "Address",
		OBJ_NAME							: "OBJ",
		FLD_NAME							: "FN",
		FLD_TYP								: "TYP",
		RLN_NAME							: "RLN",
		REF_OBJ_NAME						: "ROBJ",
		REF_FLD_NAME						: "RFN",
		REF_FLD_TYP							: "RTYP",
		RLN_NAME_2							: "RLN2",
		REF_OBJ_NAME_2						: "ROBJ2",
		REF_FLD_NAME_2						: "RFN2",
		REF_FLD_TYP_2						: "RTYP2",
		TYPE_HEADER							: "Header_Object",
		TYPE_DETAIL							: "Detail_Object",
		LOCALE							    : "Locale",
		IMAGENAMEID							: "ImageNameId",
		CANCEL                              : "Cancel",
		SAVE                                : "Save"
				
	});
}	
})();

// end of file
