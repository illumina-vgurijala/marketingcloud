import {
	consoleLog,
	showWarningToast,
	isBlank,
	isEmpty,
	isNotEmpty,
	isNotNull,
	callServer,
	isNotBlank,
} from "c/utils";
import initRecords from "@salesforce/apex/PlanCreationController.initRecords";
const STRING_SEPARATOR = "|";
const loadSharedData = (context, argument, type) => {
	callServer(
		initRecords,
		argument,
		(result) => {
			consoleLog("data -->", result);
			if (type === "New" && !context.isMobile){
				context.template.querySelector('.divblock').classList.add('divHeight');
			}
			let data = JSON.parse(result);
			let returndata = data.lstUserTerritory2Association;
			context.mapUILabels = data.mapLabels;
			context.isOverLayPlan = data.isOverlayPlan;
			context.idRecordTypeId = data.recordTypeID; //DCP-39621 : to fetch recordTypeId
			context.isCommunity = data.boolIsCommunity;
			if (context.isCommunity) {
				context.idChannelPartner = data.channelPartnerId;
				context.channelPartnerCode = data.strChannelPartnerIndirectCode;
				// DCP-41767
				context.channelPartnerName = data.strChannelPartnerName;
				if (
					isBlank(context.channelPartnerCode) ||
					isBlank(context.idChannelPartner)
				) {
					showWarningToast(context.mapUILabels.UI_Error_No_CP);
					context.closeModal();
				}
				// DCP-40495
				context.mapAccountToMapYearQuota[context.idChannelPartner] =
					data.objAccountDetailCP;
			}
			context.isIndirectRecord = data.boolIsIndirect;
			context.mapAccountWrapper = data.mapAccountWrapper;
			context.modalHeader =
				type === "New"
					? context.mapUILabels.UI_Label_Select_Territory
					: context.mapUILabels.UI_Label_Clone_Plan;
			if (!context.isOverLayPlan) {
				if (type === "New") {
					context.pathStages.push(
						context.mapUILabels.UI_Label_Select_Territory
					);
					context.pathStages.push(
						context.mapUILabels.UI_Label_Create_Plan
					);
				}
				if (returndata.length == 1) {
					context.hasSingleTerritory = true;
					context.territoryId = returndata[0].strTerritoryId;
					context.territoryCode = returndata[0].strTerritoryCode;
					context.territoryName = returndata[0].strTerritoryName;
					context.territoryRegion = returndata[0].strTerritoryRegion;
					// DCP-39735
					if (context.isIndirectRecord && !context.isCommunity)
						context.createChannelPartnerOptionList();
					context.territorySelectView = false;
					context.selectionView = true;
					context.yearSelectView = true;
					context.roleSelectView = false;
					context.booLoading = false;
				} else if (returndata.length > 1) {
					returndata.forEach((element) => {
						let dummy =
							element.strTerritoryName +
							STRING_SEPARATOR +
							element.strTerritoryCode +
							STRING_SEPARATOR +
							element.strTerritoryId +
							STRING_SEPARATOR +
							element.strTerritoryRegion;
						context.territoryOptions.push({
							label: element.strTerritoryName,
							value: dummy,
						});
					});
					context.selectionView = true;
					context.yearSelectView = true;
					context.territorySelectView = true;
					context.booLoading = false;
				} else if (returndata.length == 0) {
					showWarningToast(
						context.mapUILabels.UI_Error_No_Territory_Assigned
					);
					context.closeModal();
				}
			}
			if (context.isOverLayPlan) {
				if (type === "New") {
					context.pathStages.push(
						context.mapUILabels.UI_Label_Select_Role
					);
					context.pathStages.push(
						context.mapUILabels.UI_Label_Create_Plan
					);
				}
				if (data.setRoles.length <= 1) {
					if (data.setRoles.length == 1) {
						context.overlayRole = data.setRoles[0];
					}
					if (type == "Clone") {
                        context.booLoading = false;
                        context.selectionView = true;
                        if(data.setRoles.length == 1){
                            context.roleSelectView = true;
                            context.roleOptions.push({
							label: data.setRoles[0],
							value: data.setRoles[0],
						});
                        }
                        else
                            context.roleSelectView = false;
					}
					if (type == "New") {
						context.lastStage =
							context.mapUILabels.UI_Label_Select_Role;
						context.selectionView = false;
						context.loadLayout();
					}
				} else if (data.setRoles.length > 1) {
					data.setRoles.forEach((element) => {
						context.roleOptions.push({
							label: element,
							value: element,
						});
					});
					context.selectionView = true;
					context.roleSelectView = true;
					context.yearSelectView = false;
					context.territorySelectView = false;
					context.booLoading = false;
				}
			}
		},
		(error) => {
			context.booLoading = false;
		}
	);
};
const createChannelPartnerOptionListHelper = (context) => {
	context.booLoading = true;
	context.channelPartnerSelectView = false;
	context.channelPartnerOption = [];
	let accountData = context.mapAccountWrapper[context.territoryCode];
	let tempchannelPartnerOption = [];
	let tempmapAccountToMapYearQuota = {};
	if (isNotEmpty(accountData)) {
		accountData.forEach((element) => {
			if (isNotNull(element.strIndirectCode)) {
				tempchannelPartnerOption.push({
					label: element.strAccountName,
					value: element.strAccountId + STRING_SEPARATOR + element.strIndirectCode+ STRING_SEPARATOR +element.strAccountName
				});

				tempmapAccountToMapYearQuota[element.strAccountId] =
					element.mapAccountIdToFYQuota;
			}
		});
	}
	consoleLog("tempmapAccountToMapYearQuota--->",tempmapAccountToMapYearQuota);
	context.mapAccountToMapYearQuota = tempmapAccountToMapYearQuota;
	if (isEmpty(tempchannelPartnerOption) && context.hasSingleTerritory) {
		showWarningToast(context.mapUILabels.UI_Error_No_CP);
		context.closeModal();
	} else if (
		isEmpty(tempchannelPartnerOption) &&
		!context.hasSingleTerritory
	) {
		showWarningToast(context.mapUILabels.UI_Error_No_CP_In_Territory);
		context.channelPartnerSelectView = true;
		context.booLoading = false;
	} else if (tempchannelPartnerOption.length == 1) {
		//Added splitting based on "|" instead of hyphen for INC0300579
		let split = tempchannelPartnerOption[0].value.split(STRING_SEPARATOR);
		context.idChannelPartner = split[0];
		context.channelPartnerCode = split[1];
		context.channelPartnerName = split[2];
		context.channelPartnerOption = tempchannelPartnerOption;
		context.channelPartnerValue = tempchannelPartnerOption[0].value;
		context.channelPartnerSelectView = true;
		context.booLoading = false;
	} else {
		context.channelPartnerOption = tempchannelPartnerOption;
		let contextNew = context;
		// To  re-render child component.
		setTimeout(function () {
			contextNew.channelPartnerSelectView = true;
			contextNew.booLoading = false;
		}, 100);
	}
};
const getYearOptions = (context) => {
	let currentYear = new Date().getFullYear();
	let i;
	let year = [];
	for (i = 0; i < 6; i++) {
		year.push({
			label: (currentYear + i).toString(),
			value: (currentYear + i).toString(),
		});
	}
	return year;
};
const territorySelectHelper = (activity, context) => {
	context.channelPartnerSelectView = false;
	context.idChannelPartner = "";
	consoleLog("Selected-->", activity.target.value);
	//Added splitting based on "|" instead of hyphen for INC0300579
	let territoryDetail = activity.target.value.split(STRING_SEPARATOR);
	context.territoryId = territoryDetail[2];
	context.territoryCode = territoryDetail[1];
	context.territoryName = territoryDetail[0];
	context.territoryRegion = territoryDetail[3];
	if (context.isIndirectRecord && !context.isCommunity)
		context.createChannelPartnerOptionList();
};
const yearSelectHelper = (activity, context) => {
	context.year = activity.target.value;
	context.startDate = new Date(context.year + "-01-01").toISOString();
	context.endDate = new Date(context.year + "-12-31").toISOString();
};
const validateInputHelper = (context,type) => {
	let flag = false;
	if (context.territorySelectView && isBlank(context.territoryName)) {
		context.template
			.querySelector(".territorySelect")
			.showHelpMessageIfInvalid();
		flag = true;
	}
	if (context.yearSelectView && isBlank(context.year)) {
		context.template.querySelector(".year").showHelpMessageIfInvalid();
		flag = true;
	}
	if (context.roleSelectView && isBlank(context.overlayRole)) {
		context.template.querySelector(".role").showHelpMessageIfInvalid();
		flag = true;
	}
	if (context.roleSelectView && type == 'Clone' && isBlank(context.startDate)) {
		consoleLog('ININ');
		context.template.querySelector(".startdate").showHelpMessageIfInvalid();
		flag = true;
	}
	if (context.roleSelectView && type == 'Clone' && isBlank(context.endDate)) {
		context.template.querySelector(".enddate").showHelpMessageIfInvalid();
		flag = true;
	}
	// DCP-39735
	if (
		context.channelPartnerSelectView &&
		((isNotBlank(context.idChannelPartner) &&
			isBlank(context.channelPartnerCode)) ||
			isBlank(context.idChannelPartner))
	) {
		consoleLog("Validate");
		context.template
			.querySelector(".channelPartner")
			.showHelpMessageIfInvalid();
		flag = true;
	}
	return flag;
};
export {
	loadSharedData,
	createChannelPartnerOptionListHelper,
	getYearOptions,
	territorySelectHelper,
	yearSelectHelper,
	validateInputHelper,
};