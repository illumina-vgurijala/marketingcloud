	//Load Javascript based on language of End-User
	function loadConditionalScript()
	{
		//Set Location of Script 
		var jHead = document.getElementsByTagName('head')[0];

		//Create Script Tag
		var jScript = document.createElement('script');
		//Add Source of Script
		var source = getUserLangURL();

		//Set Attributes 
		jScript.setAttribute("type", "text/javascript");
		jScript.setAttribute("src", source);
		jScript.setAttribute("charset", "utf-8");
		
		//Insert Script Dynamically
		jHead.appendChild(jScript)
	}
	/*Get Javascript language library link for logged-in user language*/
	function getUserLangURL() {
		var jsURL;
		var userLanguage = '{!strUserLanguage}';
		switch (userLanguage) {
			//CHINESE
			case "zh_CN":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_cn.js'))}";
				break;
			//CHINESE
			case "zh_TW":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_cn.js'))}";
				break;
			//DUTCH
			case "nl_NL":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_nl.js'))}";
				break;
			//FRENCH
			case "fr":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_fr.js'))}";
				break;
			//GERMAN
			case "de":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_de.js'))}";
				break;
			//ITALIAN
			case "it":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_it.js'))}";
				break;
			//JAPANESE
			case  "ja":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_jp.js'))}";
				break;
			//KOREAN ****WILL RETURN ENGLISH***
			case  "ko":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_en.js'))}";
				break;
			//PORTUGESE
			case  "pt_BR":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_pt.js'))}";
				break;
			//SPANISH
			case  "es":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_es.js'))}";
				break;
			//SWEDISH
			case  "sv":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_sv.js'))}";
				break;
			//ENGLISH
			case  "en_US":
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_en.js'))}";
				break;
			// DEFAULT
			default:
				jsURL = "{!JSENCODE(URLFOR($Resource.SVMX_Scheduler, 'dhtmlxScheduler/codebase/locale/locale_en.js'))}";
			}
			return jsURL;
	}
	
	loadConditionalScript();