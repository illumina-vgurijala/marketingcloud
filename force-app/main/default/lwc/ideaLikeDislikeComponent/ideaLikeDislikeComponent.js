import { LightningElement,api } from 'lwc';
import {    
    consoleError,
    callServer,
    consoleLog
} from 'c/utils';
import { updateRecord } from 'lightning/uiRecordApi';
import ideaLiked from '@salesforce/apex/IdeaLikeDislikeComponentController.ideaLiked';
import updateVote from '@salesforce/apex/IdeaLikeDislikeComponentController.updateVote';
var voteSel;

export default class IdeaLikeDislikeComponent extends LightningElement {       
    @api recordId;   
    isSelected; 

    connectedCallback(){           
        this.initializeData();
    }

    initializeData(){         
        consoleLog('init recordId==>'+this.recordId);   
        callServer(ideaLiked,{
            ideaId:this.recordId           
        },result =>{                   
            consoleLog('result is '+result);                                       
            if(result){                                
                this.isSelected = result; 
            }else{
                this.isSelected=false;
            }                                               
        }, error => {
            consoleError('error ',JSON.stringify(error));
        });
    }       
        
    handleClick(userSelection) { 
        voteSel = userSelection;
        updateVote( {vote: voteSel, ideaId: this.recordId});
        updateRecord({ fields: { Id: this.recordId }});        
    }

    handleClickLike()
    {
        this.isSelected = true;
        this.handleClick(true);
    }
    handleClickDislike()
    {
        this.isSelected = false;
        this.handleClick(false);
    }
    
}