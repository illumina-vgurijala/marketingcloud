import UI_Text_MandatoryCodeTypes from '@salesforce/label/c.UI_Text_MandatoryCodeTypes';
import WorkOrderTypeProfessionalServices from '@salesforce/label/c.WorkOrderTypeProfessionalServices';
import CaseStatusCompleted from '@salesforce/label/c.CaseStatusCompleted';
import WorkOrderTypePreventativeMaintenance from '@salesforce/label/c.WorkOrderTypePreventativeMaintenance';
import WorkOrderTypeInstallation from '@salesforce/label/c.WorkOrderTypeInstallation';
import WorkOrderTypeRelocation from '@salesforce/label/c.WorkOrderTypeRelocation';
import Profile_Quality_Assurance from '@salesforce/label/c.Profile_Quality_Assurance';
import Profile_Service_Logistics from '@salesforce/label/c.Profile_Service_Logistics';
import WorkOrderTypeTradeinEOL from '@salesforce/label/c.WorkOrderTypeTradeinEOL';
import CaseRecordTypeBusinessIssue from '@salesforce/label/c.CaseRecordTypeBusinessIssue';
import CaseSubTypeComplaint from '@salesforce/label/c.CaseSubTypeComplaint';
import CaseSubTypeGeneralIssue from '@salesforce/label/c.CaseSubTypeGeneralIssue';
import CaseCategoryLogistics from '@salesforce/label/c.CaseCategoryLogistics';
import AssociatedCodeTypeAnalysis from '@salesforce/label/c.AssociatedCodeTypeAnalysis';
import AssociatedCodeTypeResolution from '@salesforce/label/c.AssociatedCodeTypeResolution';
import AssociatedCodeTypeLogistics from '@salesforce/label/c.AssociatedCodeTypeLogistics';
import IPRegulatoryTypeDX from '@salesforce/label/c.IPRegulatoryTypeDX';
import WorkOrderTypeServiceActivities from '@salesforce/label/c.WorkOrderTypeServiceActivities';
import WorkOrderRecordTypeServiceSupport from '@salesforce/label/c.WorkOrderRecordTypeServiceSupport';
import WorkOrderRecordTypeRemoteSupport from '@salesforce/label/c.WorkOrderRecordTypeRemoteSupport';
import WorkOrderRecordTypeFieldService from '@salesforce/label/c.WorkOrderRecordTypeFieldService';
import CaseRecordTypeInquiry from '@salesforce/label/c.CaseRecordTypeInquiry';
import CaseRecordTypeServiceRequest from '@salesforce/label/c.CaseRecordTypeServiceRequest';
import AssociatedCodeTypeSubject from '@salesforce/label/c.AssociatedCodeTypeSubject';
import CaseStatusPendingQAReview from '@salesforce/label/c.CaseStatusPendingQAReview';
import AssociatedCodeTypeHazard from '@salesforce/label/c.AssociatedCodeTypeHazard';
import AssociatedCodeTypeVerification from '@salesforce/label/c.AssociatedCodeTypeVerification';
import CaseStatusClosed from '@salesforce/label/c.CaseStatusClosed';
import UserTypeStandard from '@salesforce/label/c.UserTypeStandard';
import UI_Error_Message_No_Code_Addition from '@salesforce/label/c.UI_Error_Message_No_Code_Addition';
import UI_Error_Message_No_Active_Code from '@salesforce/label/c.UI_Error_Message_No_Active_Code';
import UI_Error_Message_No_Code_Found from '@salesforce/label/c.UI_Error_Message_No_Code_Found';
import AssociatedCodesWarningMessage from '@salesforce/label/c.AssociatedCodesWarningMessage';
import CaseStatusInitiated from '@salesforce/label/c.CaseStatusInitiated';
import CaseStatusAwaitingResponseCustomer from '@salesforce/label/c.AssociatedCodesWarningMessage';
import CaseStatusAwaitingResponseInternal from '@salesforce/label/c.CaseStatusAwaitingResponseInternal';
import CaseStatusInProgress from '@salesforce/label/c.CaseStatusInProgress';
import Completed from '@salesforce/label/c.Completed';
import Closed from '@salesforce/label/c.Closed';
import Canceled from '@salesforce/label/c.Canceled';
import ReopenRequested from '@salesforce/label/c.ReopenRequested';
import PendingReviewOrderStatus from '@salesforce/label/c.PendingReviewOrderStatus';
import WorkOrderStatusClosedDuplicate from '@salesforce/label/c.WorkOrderStatusClosedDuplicate';
import WorkOrderTypeBillableInstall from '@salesforce/label/c.WorkOrderTypeBillableInstall'; //CMCM-12461



const LABELS = {
    'AssociatedCodeTypeVerification':AssociatedCodeTypeVerification,
    'UI_Error_Message_No_Code_Found':UI_Error_Message_No_Code_Found,
    'UI_Error_Message_No_Active_Code':UI_Error_Message_No_Active_Code,
    'UI_Error_Message_No_Code_Addition':UI_Error_Message_No_Code_Addition,
    'UI_Text_MandatoryCodeTypes': UI_Text_MandatoryCodeTypes,
    'WorkOrderTypeProfessionalServices': WorkOrderTypeProfessionalServices,
    'CaseStatusCompleted': CaseStatusCompleted,
    'WorkOrderTypePreventativeMaintenance': WorkOrderTypePreventativeMaintenance,
    'WorkOrderTypeInstallation': WorkOrderTypeInstallation,
    'WorkOrderTypeRelocation': WorkOrderTypeRelocation,
    'Profile_Quality_Assurance': Profile_Quality_Assurance,
    'Profile_Service_Logistics': Profile_Service_Logistics,
    'WorkOrderTypeTradeinEOL': WorkOrderTypeTradeinEOL,
    'CaseRecordTypeBusinessIssue': CaseRecordTypeBusinessIssue,
    'CaseSubTypeComplaint': CaseSubTypeComplaint,
    'CaseSubTypeGeneralIssue': CaseSubTypeGeneralIssue,
    'CaseCategoryLogistics': CaseCategoryLogistics,
    'AssociatedCodeTypeAnalysis': AssociatedCodeTypeAnalysis,
    'AssociatedCodeTypeResolution': AssociatedCodeTypeResolution,
    'AssociatedCodeTypeLogistics': AssociatedCodeTypeLogistics,
    'IPRegulatoryTypeDX': IPRegulatoryTypeDX,
    'WorkOrderTypeServiceActivities': WorkOrderTypeServiceActivities,
    'WorkOrderRecordTypeServiceSupport': WorkOrderRecordTypeServiceSupport,
    'WorkOrderRecordTypeRemoteSupport' : WorkOrderRecordTypeRemoteSupport,
    'WorkOrderRecordTypeFieldService': WorkOrderRecordTypeFieldService,
    'CaseRecordTypeInquiry': CaseRecordTypeInquiry,
    'CaseRecordTypeServiceRequest': CaseRecordTypeServiceRequest,
    'AssociatedCodeTypeSubject': AssociatedCodeTypeSubject,
    'CaseStatusPendingQAReview': CaseStatusPendingQAReview,
    'AssociatedCodeTypeHazard': AssociatedCodeTypeHazard,
    'CaseStatusClosed': CaseStatusClosed,
    'UserTypeStandard': UserTypeStandard,
    'AssociatedCodesWarningMessage': AssociatedCodesWarningMessage,
    'CaseStatusInitiated' : CaseStatusInitiated,
    'CaseStatusAwaitingResponseCustomer': CaseStatusAwaitingResponseCustomer,
    'CaseStatusAwaitingResponseInternal': CaseStatusAwaitingResponseInternal,
    'CaseStatusInProgress': CaseStatusInProgress,
    'Completed': Completed,
    'Closed': Closed,
    'Canceled': Canceled,
    'ReopenRequested': ReopenRequested,
    'PendingReviewOrderStatus': PendingReviewOrderStatus,
    'WorkOrderStatusClosedDuplicate': WorkOrderStatusClosedDuplicate,
    'WorkOrderTypeBillableInstall': WorkOrderTypeBillableInstall
};

const CONSTANTS = {
    'CaseFields': [
        'Case.Category__c','Case.HasHazardCode__c', 'Case.Status', 'Case.PAE_PFA_Evaluation_Required__c', 'Case.IVD_Product_Identifier__c', 'Case.IVD_Product_Identifier_Additional_Prod__c', 'Case.QA_Review__c', 'Case.Has_BI_Case_Subject_Code__c', 'Case.Has_SR_Case_Subject_Code__c', 'Case.Has_Inquiry_Case_Subject_Code__c', 'Case.Has_Verification_Code__c', 'Case.Work_Order__r.Has_Verification_Code__c', 'Case.Work_Order__r.SVMXC__Product__r.Regulatory_Type__c', 'Case.Work_Order__r.SVMXC__Product__c', 'Case.Work_Order__r.SVMXC__Product__r.Service_Product_Type__c', 'Case.Has_Analysis_Code__c', 'Case.Has_Resolution_Code__c', 'Case.Work_Order__r.Record_Type__c', 'Case.Work_Order__c', 'Case.Record_Type__c', 'Case.Work_Order__r.Abandoned_Reason__c', 'Case.Sub_Type__c','Case.Work_Order__r.SVMXC__Order_Status__c'
    ],
    'WorkOrderFields': [
        'SVMXC__Service_Order__c.SVMXC__Case__r.HasHazardCode__c','SVMXC__Service_Order__c.SVMXC__Order_Type__c','SVMXC__Service_Order__c.SVMXC__Case__r.Category__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Status', 'SVMXC__Service_Order__c.SVMXC__Case__r.PAE_PFA_Evaluation_Required__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.IVD_Product_Identifier__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.IVD_Product_Identifier_Additional_Prod__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.QA_Review__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_BI_Case_Subject_Code__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_SR_Case_Subject_Code__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_Inquiry_Case_Subject_Code__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_Verification_Code__c', 'SVMXC__Service_Order__c.Has_Verification_Code__c', 'SVMXC__Service_Order__c.SVMXC__Product__r.Regulatory_Type__c', 'SVMXC__Service_Order__c.SVMXC__Product__c', 'SVMXC__Service_Order__c.SVMXC__Product__r.Service_Product_Type__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_Analysis_Code__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_Resolution_Code__c', 'SVMXC__Service_Order__c.Record_Type__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Work_Order__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Record_Type__c', 'SVMXC__Service_Order__c.Abandoned_Reason__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Sub_Type__c','SVMXC__Service_Order__c.SVMXC__Order_Status__c'
    ], 
    'AssociatedCodeFields' :[
        'Associated_Codes__c.Parent_Code__r.Name', 'Associated_Codes__c.Case_Type__c', 'Associated_Codes__c.Case__c', 'Associated_Codes__c.Work_Order__c', 'Associated_Codes__c.Code_Description__c', 'Associated_Codes__c.Code_Title__c', 'Associated_Codes__c.Code_Type__c', 'Associated_Codes__c.Parent_Code__c'
    ],
    'orderTypesToCheck': [
        WorkOrderTypeProfessionalServices, WorkOrderTypePreventativeMaintenance, WorkOrderTypeInstallation, WorkOrderTypeRelocation,WorkOrderTypeTradeinEOL
    ],
    'PRODUCTTYPE_INSTRUMENT': 'Instrument',
    'REGULATORYTYPE_DX': 'DX',
    'REGULATORYTYPE_EUA': 'EUA',
    'REGULATORYTYPE_IUO': 'IUO',
    'SUBTYPE_ORDER': 'Order',
    'SUBTYPE_GENERAL': 'General',
    'QAREVIEW_NONIVDPRODUCT': 'Non IVD Product',
    'STRING_NO': 'No',
    'STRING_YES': 'Yes',
    'CaseOptionalFields':[
        'Case.Id', 'Case.Category__c','Case.HasHazardCode__c', 'Case.Status', 'Case.PAE_PFA_Evaluation_Required__c', 'Case.IVD_Product_Identifier__c', 'Case.IVD_Product_Identifier_Additional_Prod__c', 'Case.QA_Review__c', 'Case.Has_BI_Case_Subject_Code__c', 'Case.Has_SR_Case_Subject_Code__c', 'Case.Has_Inquiry_Case_Subject_Code__c', 'Case.Has_Verification_Code__c', 'Case.Work_Order__r.Has_Verification_Code__c', 'Case.Work_Order__r.SVMXC__Product__r.Regulatory_Type__c', 'Case.Work_Order__r.SVMXC__Product__c', 'Case.Work_Order__r.SVMXC__Product__r.Service_Product_Type__c', 'Case.Has_Analysis_Code__c', 'Case.Has_Resolution_Code__c', 'Case.Work_Order__r.Record_Type__c', 'Case.Work_Order__c', 'Case.Record_Type__c', 'Case.Work_Order__r.Abandoned_Reason__c', 'Case.Sub_Type__c','Case.Work_Order__r.SVMXC__Order_Type__c','Case.Work_Order__r.SVMXC__Order_Status__c'
    ],

    'WOOptionalFields':[
        'SVMXC__Service_Order__c.Id','SVMXC__Service_Order__c.SVMXC__Order_Type__c','SVMXC__Service_Order__c.SVMXC__Case__r.Category__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.HasHazardCode__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Status', 'SVMXC__Service_Order__c.SVMXC__Case__r.PAE_PFA_Evaluation_Required__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.IVD_Product_Identifier__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.IVD_Product_Identifier_Additional_Prod__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.QA_Review__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_BI_Case_Subject_Code__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_SR_Case_Subject_Code__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_Inquiry_Case_Subject_Code__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_Verification_Code__c', 'SVMXC__Service_Order__c.Has_Verification_Code__c', 'SVMXC__Service_Order__c.SVMXC__Product__r.Regulatory_Type__c', 'SVMXC__Service_Order__c.SVMXC__Product__c', 'SVMXC__Service_Order__c.SVMXC__Product__r.Service_Product_Type__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_Analysis_Code__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Has_Resolution_Code__c', 'SVMXC__Service_Order__c.Record_Type__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Work_Order__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Record_Type__c', 'SVMXC__Service_Order__c.Abandoned_Reason__c', 'SVMXC__Service_Order__c.SVMXC__Case__r.Sub_Type__c', 'SVMXC__Service_Order__c.Has_Resolution_Code__c','SVMXC__Service_Order__c.SVMXC__Order_Status__c'
    ]
};

const ASSOCIATEDCODESCOLUMNS = 
    [
        
        {
            label: 'Code Id', 
            fieldName: 'Code_ID__c', 
            type: 'text', 
            sortable: true,
            initialWidth : 100,
            sortDirection:'asc'	
        },
        {
            type: 'button-icon',
            fixedWidth: 15,
            typeAttributes: {
                iconName: 'action:info',
                name: 'Info', 
                title:  {fieldName: 'Code_Description__c'},
                alternativeText:  {fieldName: 'Code_Description__c'},
                variant : "bare",
                disabled: {fieldName : 'disable'}
            }
        },
        {
            label: 'Code Title', 
            fieldName: 'Code_Title_Name__c', 
            type: 'text', 
            sortable: true,
            wrapText: true,
            sortDirection:'asc'	
        },
        {
            label: 'Code Type', 
            fieldName: 'Code_Type__c', 
            type: 'text', 
            sortable: true,
            initialWidth : 110,
            sortDirection:'asc'	
        },
        {
            label: 'Case Type', 
            fieldName: 'Case_Type__c', 
            type: 'text', 
            sortable: true,
            initialWidth : 130,
            sortDirection:'asc'	
        },
        {
            label: 'Parent Code',
            fieldName: 'Parent_Code_Id',
            type: 'url',
            typeAttributes: {label: { fieldName: 'Parent_Code_Name' },
            target: '_blank'},
            sortable: true,
            initialWidth : 100
        },
        {
            type: 'button-icon',
            fixedWidth: 60,
            typeAttributes: {
                iconName: 'action:close',
                name: 'Remove_Record', 
                title: 'Remove',
                variant: 'bare',
                alternativeText: 'Remove',
                size : 'small',
                disabled: {fieldName : 'isActive'},
                iconClass:'slds-icon-text-error'
            }
        }
    ];

const CODELIBCOLUMNS=[
        
        {
            label: 'Code Id', 
            fieldName: 'Code_ID__c', 
            type: 'text', 
            sortable: true,
            initialWidth : 100,
            sortDirection:'asc'	
            
        },
        {
            type: 'button-icon',
            fixedWidth: 15,
            typeAttributes: {
                iconName: 'action:info',
                name: 'Info', 
                title:  {fieldName: 'Code_Description__c'},
                alternativeText:  {fieldName: 'Code_Description__c'},
                variant : "bare",
                disabled: {fieldName : 'disable'}
            }
        },
        {
            label: 'Code Title', 
            fieldName: 'Name', 
            type: 'text', 
            sortable: true,
            wrapText: true,
            sortDirection:'asc'
            
        },
        {
            label: 'Code Type', 
            fieldName: 'Code_Type__c', 
            type: 'text', 
            sortable: true,
            initialWidth : 110,
            sortDirection:'asc'
            
        },
        {
            label: 'Case Type', 
            fieldName: 'Case_Type__c', 
            type: 'text', 
            sortable: true,
            initialWidth : 130,
            sortDirection:'asc'
            
        },
        {
            label: 'Parent Code Title',
            fieldName: 'Parent_Code_Name',
            type: 'text',
            typeAttributes: {label: { fieldName: 'Parent_Code_Name' },
            target: '_blank'},
            sortable: true,
            initialWidth : 100
        },
        {
            type: 'button-icon',
            fixedWidth: 60,
            typeAttributes: {
                iconName: 'utility:new',
                name: 'Add_Record', 
                title: 'Add',
                variant: 'bare',
                alternativeText: 'Add',
                size : 'small',
                disabled: false,
                iconClass:'slds-icon-text-success'
            }
        }
];

function setFields(data, objectApiName) {
    let caseObj = {};
    let workOrderObj = {};
    let productObj = {};

    if (objectApiName === 'Case') {
        setCaseAndRelatedFields(data, caseObj, workOrderObj, productObj);
    } else if (objectApiName === 'SVMXC__Service_Order__c') {
        setWorkOrderAndRelatedFields(data, caseObj, workOrderObj, productObj);
    }

    return { caseObj, workOrderObj, productObj };
}

function setCaseAndRelatedFields(data, caseObj, workOrderObj, productObj) {
    for (let field in data.fields) { 
        if (!field.includes('__r'))
            caseObj[field] = data.fields[field].value;
        else if (field === 'Work_Order__r') {
            workOrderObj.Id = data.fields[field].value?.id;

            let childFields = data.fields[field].value?.fields;
            setWorkOrderFields(childFields, workOrderObj, productObj)
        }
    }
}

function setWorkOrderFields(childFields, workOrderObj, productObj) {
    for (let childField in childFields) {
        if (!childField.includes('__r'))
            workOrderObj[childField] = childFields[childField].value;
        else if (childField === 'SVMXC__Product__r') {
            let child1Fields = childFields[childField].value?.fields;
            for (let child1Field in child1Fields) {
                productObj[child1Field] = child1Fields[child1Field].value;
            }
        }
    }
}

function setWorkOrderAndRelatedFields(data, caseObj, workOrderObj, productObj) {
    for (let field in data.fields) {
        if (!field.includes('__r'))
            workOrderObj[field] = data.fields[field].value;
        else if (field === 'SVMXC__Case__r') {
            caseObj.Id = data.fields[field].value?.id;

            let childFields = data.fields[field].value?.fields;
            for (let childField in childFields) {
                caseObj[childField] = childFields[childField].value;
            }
        }
        else if (field === 'SVMXC__Product__r') {
            productObj.Id = data.fields[field].value?.id;

            let childFields = data.fields[field].value?.fields;
            for (let childField in childFields) {
                productObj[childField] = childFields[childField].value;
            }
        }
    }
}

export { 
    LABELS, CONSTANTS, ASSOCIATEDCODESCOLUMNS, CODELIBCOLUMNS, setFields
};