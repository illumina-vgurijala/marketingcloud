import { LightningElement, track, api } from 'lwc';
import getFilesList from '@salesforce/apex/EnhancedFileListController.getFilesList';
import {NavigationMixin} from 'lightning/navigation';

import {showErrorToast, isNotEmpty, callServer} from 'c/utils';

import UI_Title_Enhanced_Files from '@salesforce/label/c.UI_Title_Enhanced_Files';
import UI_Toggle_Hide_Logos from '@salesforce/label/c.UI_Toggle_Hide_Logos';
import UI_Menu_Item_Download_Select_Files from '@salesforce/label/c.UI_Menu_Item_Download_Select_Files';
import UI_Menu_Item_Download_All_Files from '@salesforce/label/c.UI_Menu_Item_Download_All_Files';
import UI_Title_Download_Files from '@salesforce/label/c.UI_Title_Download_Files';
import UI_Button_Cancel from '@salesforce/label/c.UI_Button_Cancel';
import UI_Button_Download from '@salesforce/label/c.UI_Button_Download';
import UI_Column_Title from '@salesforce/label/c.UI_Column_Title';
import UI_keyword_hidden from '@salesforce/label/c.UI_keyword_hidden';
import UI_Error_Message_System_Error from '@salesforce/label/c.UI_Error_Message_System_Error';
import UI_EnhancedFiles_Tooltip from '@salesforce/label/c.UI_EnhancedFiles_Tooltip';

export default class EnhancedFilesCmp extends NavigationMixin(LightningElement)  {
    @api recordId;
    @api colName;
    @api offset;
    @api includeChildRecords;

    @track enhancedFiles = [];
    @track showLoading = false;
    @track hiddenFilesCount = '0';
    @track column = [];
    @track enhancedFilesSize;
    @track showModal = false;
    @track downloadSize = 0 ;
    @track filesToDownloadCount = 0 ;
    @track modalBody = "";
    selectedRecs = [] ;
    fileIds = [];
    preselectedRows =[]

    label = {UI_Title_Enhanced_Files, UI_Toggle_Hide_Logos, UI_Menu_Item_Download_Select_Files, 
            UI_Menu_Item_Download_All_Files, UI_Title_Download_Files, UI_Button_Cancel, UI_Button_Download, 
            UI_Column_Title, UI_keyword_hidden, UI_Error_Message_System_Error, UI_EnhancedFiles_Tooltip
    };

    connectedCallback() {
        this.hiddenFilesCount = '0 ' + this.label.UI_keyword_hidden;
        this.showLoading = true;
        this.colName.split(';').forEach(element => {
            if(element === this.label.UI_Column_Title) {
                this.column.push({
                    label: element,
                    fieldName: 'RecordURL',
                    sortable: true,
                    type: 'url',
                    typeAttributes: {
                        label: { 
                            fieldName: this.label.UI_Column_Title 
                        },
                        target : '_self'
                    }
                });
            } else {
                this.column.push({
                    label: element,
                    fieldName: element.replaceAll(' ',''),
                    sortable: true,
                    initialWidth:185
                });
            }
            
        });
    
        callServer(getFilesList, {
            recordId: this.recordId,
            excludeLogos: true,
            includeChildEmailRecs: this.includeChildRecords
        }, result => {
            this.enhancedFiles = result.enhancedFiles;
            this.enhancedFiles = result.enhancedFiles;
            this.enhancedFilesSize = this.enhancedFiles.length;
            this.hiddenFilesCount = result.hiddenFilesCount + ' ' + this.label.UI_keyword_hidden;
            this.showLoading = false;
        }, error => {
            this.showLoading = false;
            showErrorToast(this.label.UI_Error_Message_System_Error);
            
        });
        
    }

    get showDataTable(){
        if(isNotEmpty(this.enhancedFiles)) {
            return true;
        }
        return false;
    }

    get disableButton() {
        if(isNotEmpty(this.selectedRecs)) {
            return false;
        } else {
            return true;
        }
    }

    handleSort(event) {
        this.showLoading = true;
        this.selectedRecs = [];
        let fieldName = event.detail.fieldName;
        if(fieldName === 'RecordURL') {
            fieldName = 'Title';
        }
        this.enhancedFiles = this.sortData(this.enhancedFiles,fieldName, event.detail.sortDirection);
        
        this.template.querySelector('c-data-table-lazy-load').resetTable(this.enhancedFiles);
	    this.showLoading = false;
         
    } 

    sortData(datalist, fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(datalist));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data 
        
        parseData.sort((x, y) => {
            let xNew = keyValue(x) ? keyValue(x) : ''; // handling null values
            let yNew = keyValue(y) ? keyValue(y) : '';
            if(fieldname.includes('Date')) {
                let xDate = new Date(xNew);
                let yDate = new Date(yNew);
                return isReverse * ((xDate > yDate) - (yDate > xDate));
            } 

            xNew = xNew.toUpperCase();
            yNew = yNew.toUpperCase();

            // sorting values based on direction
            return isReverse * ((xNew > yNew) - (yNew > xNew));
        });
        // set the sorted data to data table data
        return parseData;

    }

    handleButtonAction(event) {
        let selectedVal = event.detail.value;
        switch (selectedVal) {
            case 'downloadSelect':
                let selectedRecords = this.template.querySelector('c-data-table-lazy-load').fetchSelectedRecord();
                if(isNotEmpty(selectedRecords)) {
                    this.openModal(selectedRecords);
                }
                break;
            case 'downloadAll':
                let allRecords = this.template.querySelector('c-data-table-lazy-load').tableDataRecords;
                this.openModal(allRecords);
                break;
        }
    }

    downloadFiles(fileIds) {
        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: window.location.origin + '/sfc/servlet.shepherd/document/download/' + fileIds.join('/')
                }
            }, false);
        }
        catch(err) {
            showErrorToast(err.message);
        }
        this.closeModal();
        this.showLoading = false;
    }

    toggleChange(event) {
        this.showLoading = true;
        this.selectedRecs = [];

        callServer(getFilesList, {
            recordId: this.recordId,
            excludeLogos: event.target.checked,
            includeChildEmailRecs: this.includeChildRecords
        }, result => {
            this.enhancedFiles = result.enhancedFiles;
            this.enhancedFilesSize = result.enhancedFiles.length;
            this.hiddenFilesCount = result.hiddenFilesCount + ' ' + this.label.UI_keyword_hidden;
            this.showLoading = false;
        }, error => {
            this.showLoading = false;
            showErrorToast(this.label.UI_Error_Message_System_Error);
            
        });
    }

    openModal(recsToDownload) {
        let fileIdValues = [];
        let contentSize = 0;
        let filesCount = 0;
        recsToDownload.forEach((element1) => {
            contentSize = contentSize + element1.ContentSize;
            fileIdValues.push(element1.ContentDocId);
            filesCount = filesCount + 1;
        });
        this.downloadSize = (contentSize/1048576).toFixed(2);
        this.filesToDownloadCount = filesCount;
        this.fileIds = fileIdValues;
        this.modalBody = 'Are you sure you want to download '+this.filesToDownloadCount+' files worth '+ this.downloadSize +' MB?';
        this.template.querySelector('c-modal-popup').openModal();
    }

    
    downloadFilesAction(event) {
        this.downloadFiles(this.fileIds);
    }

    selectRecs(event) {
        this.selectedRecs = event.detail;
    }

    closeModal() {
        this.template.querySelector('c-modal-popup').closeModal();
    }
    
}