import { LightningElement,api } from 'lwc';
import myLogo from '@salesforce/resourceUrl/myLogo';
import { getRecord } from 'lightning/uiRecordApi';
import getSections from '@salesforce/apex/BMA_AccelerateController.getSections';
import getCurrentField from '@salesforce/apex/BMA_AccelerateController.getCurrentField';
import getSecttionDetail from '@salesforce/apex/BMA_AccelerateController.getSecttionDetail';
import updateResponseChoiceForRadioType from '@salesforce/apex/BMA_AccelerateController.updateResponseChoiceForRadioType';
import updateResponseChoiceForCheckboxType from '@salesforce/apex/BMA_AccelerateController.updateResponseChoiceForCheckboxType';
import updateResponseChoiceForTextType from '@salesforce/apex/BMA_AccelerateController.updateResponseChoiceForTextType';
import updateResponseChoiceForAdditionalInfo from '@salesforce/apex/BMA_AccelerateController.updateResponseChoiceForAdditionalInfo';
import saveCurrentSequenceNext from '@salesforce/apex/BMA_AccelerateController.saveCurrentSequenceNext';
import saveCurrentSequenceBack from '@salesforce/apex/BMA_AccelerateController.saveCurrentSequenceBack';
import saveCurrentField from '@salesforce/apex/BMA_AccelerateController.saveCurrentField';
import UploadCompanyLogo from '@salesforce/apex/BMA_AccelerateController.UploadCompanyLogo';
import getFileUrl from '@salesforce/apex/BMA_AccelerateController.getFileUrl';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import BMAComponentHelpText from '@salesforce/resourceUrl/BMAComponentHelpText';
export default class Bma_OpptoClose extends LightningElement {

    @api recordId;
    // menuItems = [
    //     'Getting Started',
    //     'Company Info',
    //     'Users / Roles',
    //     'Lead Setup',
    //     'Account Setup',
    //     'Contact Setup',
    //     'Opportunity Setup',
    //     'Automation',
    //     'Reports / Dashboards',
    //     'Future Needs',
    //     'Finish / Schedule Call'
    // ];

    @api projectId;

    sections = [];
    completedSections = [];
    imageURL = myLogo;
    responses = [];
    currentSection = '';
    currentSectionName = '';
    currentScreen = '';
    currentSectionScreenCount = 1;
    currentSectionOnScreen    = 1;
    currentSectionOnScreenForHeader = '';
    sectionId = '';
    sectionProgressBar = '0.00%';
    onboardingProgressBar = '0.00%';
    sectionState = {};
    totalScreenCount = 0;
    totalScreenCompleteCount = 0;
    onboardingProgressComplete = false;
    radioResponseValues = [];
    textResponseValues = [];
    checkboxResponseValues = [];
    checkboxTrueResponseValues = [];
    checkboxFalseResponseValues = [];
    additionalInfoResponseId = '';
    additionalInfoValue = '';
    additionalInfoResponseValues = [];
    currentScreenResponseIds = [];
    showFinishLater = false;
    showIntakeContainer = true;
    showSaveButton = true;
    showSectionProgressBar = true;
    showOnboardingProgressBar = true;
    showAdditionalInfoBox = false;
    showScreenNumber = false;
    lastSectionId = '';

    //logo variable
    fileName = '';
    fileData;   
    imagePreview;
    //isPreview = false;
    savedImageUrl;
    uploadedFile;
    isLoading = false ;

     helpText = '';
     showModal = false;

    connectedCallback(){
        //this.projectId = '';
        //console.log(this.projectId);
        this.loadSavedImage();
        this.loadComponentData();
    } 


    loadComponentData(){
        getSections({ intakeId: this.projectId })
        .then(result => {
            this.sections = result.sections;
            console.log('this.sections',this.sections);

            this.sections.forEach(section => {
                this.totalScreenCount += section.screenCount;
                console.log('sequence1',section.Sequence );
                console.log('currentsequence1',section.currentSequence );
                if(section.Sequence == section.currentSequence){
                    this.sectionId = section.Id;
                    this.currentSection = section.Id;
                    this.currentSectionName = section.Name;
                    this.currentSectionScreenCount = section.screenCount || 1;
                    if(this.currentSectionScreenCount > 1){
                        this.showScreenNumber = true;
                    }
                    else{
                        this.showScreenNumber = false;
                    }

                    getCurrentField({intakeId : this.projectId, sectionId : this.currentSection})
                    .then(res => {
                        this.currentSectionOnScreen = parseInt(res) || 1;
                        this.currentScreen = res;

                        this.currentSectionOnScreenForHeader = this.currentSectionOnScreen.toString();
                        this.totalScreenCompleteCount += this.currentSectionOnScreen-1;
                        
                        this.resetSelectedSection();
                        Promise.resolve().then(() => {
                            this.getOnboardingProgress();
                            const FirstButton = this.template.querySelector(`button[data-id="${this.sectionId}"]`);
                            if (FirstButton) {
                                FirstButton.classList.add('sidebar-button-selected');
                            }
                        });

                        this.loadSectionByScreen();
                    }
                    )

                }
                else if(section.Sequence < section.currentSequence){
                    this.totalScreenCompleteCount += section.screenCount;
                    this.completedSections.push(section.Id);
                    console.log('completedSections',JSON.stringify(this.completedSections));
                }
               console.log('a', section.Sequence);
               console.log('b', section.currentSequence);
               console.log('c', this.currentScreen);
            })
            Promise.resolve().then(() => {
                this.grayCompletedSections();
                //this.getOnboardingProgress();
                this.getSectionProgress();
            });
    
        })
        .catch(error => {
            console.error('Error fetching data1', error);            
        });
    }

    sectionClick(event){
        const sectionId = event.target.dataset.id; 
        const currenentSectionDetail = this.sections.find(item => item.Id === sectionId);
        console.log('currenentSectionDetail : ',currenentSectionDetail);
        this.sectionId = sectionId;
        this.currentSectionScreenCount = currenentSectionDetail.screenCount;
        
        this.showScreenNumber = this.currentSectionScreenCount > 1;
        this.currentSection = sectionId;

        const currentSectionIndex = this.sections.findIndex(sec => sec.Id === sectionId);
        this.totalScreenCompleteCount = 0;
        for (let i = 0; i < currentSectionIndex; i++) {
            this.totalScreenCompleteCount += this.sections[i].screenCount;
        }

        if (this.onboardingProgressComplete == true){
            this.onboardingProgressComplete = false;
        }
        // also add progress inside the current section (if savedScreen > 1)
        //this.totalScreenCompleteCount += (this.currentSectionOnScreen - 1);
        //this.currentScreen  = '1';
        const savedScreen = this.sectionState[sectionId]?.screen || 1;
        this.currentSectionOnScreen = 1;
        this.currentScreen = this.currentSectionOnScreen.toString();
        this.currentSectionName = currenentSectionDetail.Name;
        this.currentSectionOnScreenForHeader = this.currentSectionOnScreen.toString();

        this.loadSectionByScreen();
        this.resetSelectedSection();
        event.target.classList.add('sidebar-button-selected');
        this.getSectionProgress();
        this.getOnboardingProgress();
        this.saveCurrentOnLoadField();
        saveCurrentSequenceNext({intakeId : this.projectId, currentSequence: currenentSectionDetail.Sequence})
            .then(result => {
                result.forEach(res => {
                    console.log('Id:', res.Id, 'Current Sequence:', res.Current_Sequence__c, 'Current Field:', res.Current_Field__c);
                });
                
                //console.log('sequence', JSON.stringify(result))
            })
    }

    loadSectionByScreen(){
        getSecttionDetail({ sectionId: this.sectionId, intakeId: this.projectId, screen: this.currentScreen})
        .then(result => {
            console.log('test',result);

            result.forEach(ques => {
                this.currentScreenResponseIds.push(ques.resoponseId);
            });

            this.responses = result
            .map(section => {
                const answerType = section.answerType?.toLowerCase();                 
                if(answerType === 'content document'){
                    let oldValue = this.savedImageUrl;
                    this.savedImageUrl = '';
                    this.savedImageUrl = oldValue;

                    console.log('this.savedImageUrl==='+this.savedImageUrl);
                }
                return {
                    ...section,
                    IsRadio: answerType === 'picklist',
                    IsCheckbox: answerType === 'multi-select',
                    IsText: answerType === 'text',
                    IsRichText: answerType === 'richtext',
                    IsEmbedded: answerType === 'embedded' ,
                    Isfile: answerType === 'content document',
                    ShowAdditionalInfo: section.additionalInfoReq,
                    responseChoices: section.responseChoices.map(choice => ({
                        ...choice,
                        isChecked: choice.isSelected 
                    })),
                };
            }); 
        })
        .catch(error => {
            console.error('Error fetching data2', error);            
        });
    }

    handleSaveAndNext(){
        //if(this.sectionId == this.lastSectionId && this.lastField == this.currentScreen){
            //this.increaseOnboardingProgress();
        //} 
        if(this.currentSectionScreenCount > this.currentSectionOnScreen) {
            this.currentSectionOnScreen += 1;
            this.totalScreenCompleteCount += 1;
            console.log("currentSectionOnScreen" , this.currentSectionOnScreen);
            this.currentScreen = this.currentSectionOnScreen.toString();
            this.sectionState[this.currentSection] = {screen: this.currentSectionOnScreen};
            this.currentSectionOnScreenForHeader = this.currentSectionOnScreen.toString();            

            Promise.resolve().then(() => {
                this.saveCurrentOnLoadField();
                this.saveRecords();
                this.loadSectionByScreen();                
                this.getOnboardingProgress();
                this.getSectionProgress();
            }); 
        }
        else {
            this.totalScreenCompleteCount += 1;
            this.saveRecords();
            this.sectionProgressBar = '0.00%';
            const currentSectionIndex = this.sections.findIndex(sec => sec.Id === this.currentSection);
            const nextSection = this.sections[currentSectionIndex + 1];

            if (nextSection) {
                this.completedSections.push(this.sectionId);
                this.currentSectionName = nextSection.Name;
                this.grayCompletedSections(); 

                this.currentSection = nextSection.Id;
                this.sectionId = nextSection.Id;
                this.currentSectionScreenCount = nextSection.screenCount;
                if(this.currentSectionScreenCount > 1){
                    this.showScreenNumber = true;
                }
                else{
                    this.showScreenNumber = false;
                }
                //const savedScreen = this.sectionState[nextSection.Id]?.screen || 1;
                this.currentSectionOnScreen = 1;
                this.currentScreen = this.currentSectionOnScreen.toString();
                this.currentSectionOnScreenForHeader = this.currentSectionOnScreen.toString();
                console.log('seq',nextSection.Sequence);

                this.saveCurrentOnLoadSequenceForNext(nextSection.Sequence);
            } else {
                //this.totalScreenCompleteCount += 1;
                this.completedSections.push(this.sectionId);
                this.grayCompletedSections();
                this.resetSelectedSection();
                this.getOnboardingProgress();
                this.getSectionProgress();  
                this.showSaveButton = false;
                this.showSectionProgressBar = false;
                this.showOnboardingProgressBar = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Completed!',
                        message: 'You have finished all sections successfully',
                        variant: 'success',
                        mode: 'sticky'
                    })
                );              
            }   
        }              
    }

    //Logo upload starts
    handleOpenFileUpload(event) {
        const file = event.target.files[0];
        if (file) {
            //this.isPreview = true;
            const fileSizeInMB = (file.size / (1024 * 1024)).toFixed(2); // Convert bytes to KB
            const fileType = file.type;

            console.log(' fileSizeInKB : ', fileSizeInMB);
            console.log(' fileType : ', fileType);

            const reader = new FileReader();
            reader.onload = (e) => {
               // const base64 = reader.result.split(',')[1];
               const base64 = e.target.result.split(',')[1];
                this.fileData = {
                    fileName: file.name,
                    base64: base64
                };
                this.imagePreview = e.target.result;
                //this.savedImageUrl = '';
                console.log('File Data:', this.fileData);
            };
            reader.readAsDataURL(file);
        }
    }

    get isPreview(){
        if(this.imagePreview){
            return true;
        }else{
            return false;
        }
    }

    get isSavedImage(){
        if(this.savedImageUrl && !this.imagePreview){
            return true;
        }else{
            return false;
        }
    }

    loadSavedImage() {
        getFileUrl({ recordId: this.projectId })
        .then(url => {
             this.savedImageUrl = url + '#t=' + new Date().getTime();
            //this.savedImageUrl = url;
        })
        .catch(err => console.error(err));
    }
    //logo upload ends

    handleBack(){
        console.log('100000000');
        if (this.onboardingProgressComplete == true){
            this.onboardingProgressComplete = false;
        }
        if(this.currentSectionScreenCount == this.currentSectionOnScreen) {   
            console.log('1');
            if(this.currentSectionOnScreen == 1){
                console.log('2');
                this.loadPrevSectionLastScreen()
            } 
            else{
                console.log('3');
                this.loadSameSectionPrevScreen();
            }    
        }
        else{
            console.log('4');
            if(this.currentSectionOnScreen == 1){
                console.log('5');
                this.loadPrevSectionLastScreen()
            } 
            else{
                console.log('6');
                this.loadSameSectionPrevScreen();
            }    
        }
    }

    loadPrevSectionLastScreen(){
        //if(!this.completedSections.includes(this.sectionId)){
            ///this.decreaseOnboardingProgress();
        //}
        const currentSectionIndex = this.sections.findIndex(sec => sec.Id === this.currentSection);
        const prevSection = this.sections[currentSectionIndex - 1];
        //console.log('currentSectionIndex',JSON.stringify(this.prevSection));
        console.log('prevSections',JSON.stringify(prevSection));
        if(prevSection) {
            console.log('hi1');
            this.totalScreenCompleteCount -= 1;
            this.currentSectionName = prevSection.Name;
            if(this.currentSection.screenCount != this.currentSection.Current_Field__c){
                this.completedSections = this.completedSections.filter(item => item !== this.sectionId);
                console.log('completedSections',JSON.stringify(this.completedSections));
                this.grayCompletedSections();
            }

            this.currentSection = prevSection.Id;
            this.sectionId = prevSection.Id;
            this.currentSectionScreenCount = prevSection.screenCount;
            //if(!this.completedSections.includes(this.sectionId)){
                //this.decreaseOnboardingProgress();
            //}
            if(this.currentSectionScreenCount > 1){
                this.showScreenNumber = true;
            }
            else{
                this.showScreenNumber = false;
            }
            

            //const savedScreen = this.sectionState[prevSection.Id]?.screen || 1;
            this.currentSectionOnScreen = prevSection.screenCount;
            this.currentScreen = this.currentSectionOnScreen.toString();
            this.currentSectionOnScreenForHeader = this.currentSectionOnScreen.toString();

            console.log('hi2');

            this.saveCurrentOnLoadSequenceForBack(prevSection.Sequence);
        }
    }

    loadSameSectionPrevScreen(){
        //if(!this.completedSections.includes(this.sectionId)){
            //this.decreaseOnboardingProgress();
        //}
        this.currentSectionOnScreen -= 1;
        this.totalScreenCompleteCount -= 1;
        console.log("currentSectionOnScreen" , this.currentSectionOnScreen);
        this.currentSectionOnScreenForHeader = this.currentSectionOnScreen.toString();

        this.currentScreen = this.currentSectionOnScreen.toString();
        this.saveCurrentOnLoadField();
        this.sectionState[this.currentSection] = {screen: this.currentSectionOnScreen};
        Promise.resolve().then(() => {
            this.loadSectionByScreen();
            this.getOnboardingProgress();
            this.getSectionProgress();
        }); 
    }

    handleFinishLater(){        
        this.showFinishLater = true;
        this.showIntakeContainer = false;
    }
    //Help button
    async openHelp() {
        try {
            const response = await fetch(BMAComponentHelpText);
            this.helpText = await response.text();
            this.showModal = true;   
        } catch (error) {
            console.error('Error loading help text:', error);
        }
    }

    closeModal() {
        this.showModal = false;
    }
    //help button end

    getSectionProgress(){
        this.sectionProgressBar = 
    (((this.currentSectionOnScreen - 1) / this.currentSectionScreenCount) * 100).toFixed(2) + '%';

    }

    get sectionProgressStyle() {
        return `width: ${this.sectionProgressBar}`;
    }

    resetSelectedSection() {
        const allButtons = this.template.querySelectorAll('.sidebar-button-selected');
    
        allButtons.forEach(button => {       
                button.classList.remove('sidebar-button-selected');
        });
    }

    grayCompletedSections(){
        const allButtons = this.template.querySelectorAll('.sidebar-btn-completed');
    
        allButtons.forEach(button => {       
            button.classList.remove('sidebar-btn-completed');
        });

        this.completedSections.forEach(section => {
            const sectionComplete = this.template.querySelector(`button[data-id="${section}"]`);
            sectionComplete.classList.add('sidebar-btn-completed');
        })
    }

    getOnboardingProgress(){
        if (!this.onboardingProgressComplete ){
            console.log("totalsccount    " , this.totalScreenCompleteCount);
            console.log("totalsccount11    " , this.totalScreenCount);
            this.onboardingProgressBar = 
           (((this.totalScreenCompleteCount / this.totalScreenCount) * 100).toFixed(2) + '%');
        }
       
        if(this.onboardingProgressBar === '100.00%'){
            this.onboardingProgressComplete = true;
        }
    }

    get onboardingProgressStyle() {
        return `width: ${this.onboardingProgressBar}`;
    }

    handleRadioResponseChange(event){
        const resp = [];
        resp.push(event.target.name);
        resp.push(event.target.value);   
        this.radioResponseValues.push(resp);
        console.log('As stringified:', JSON.stringify(this.radioResponseValues));
    }

    handleTextResponseChange(event) {
        const resp = [];
        resp.push(event.target.name);
        resp.push(event.target.value);   
        this.textResponseValues.push(resp);
    }  
    
    handleMultiSelectResponseChange(event){
        const resp = [];
        if(event.target.checked) {
            resp.push(event.target.name);
            resp.push(event.target.value);
            this.checkboxTrueResponseValues.push(resp);
        }
        else {
            resp.push(event.target.name);
            resp.push(event.target.value);
            this.checkboxFalseResponseValues.push(resp);
        } 
        this.checkboxResponseValues.push(resp);
        console.log(event.target.name);
        console.log(event.target.value);
        console.log('As stringified:', JSON.stringify(this.checkboxTrueResponseValues));
        console.log('As stringified:', JSON.stringify(this.checkboxFalseResponseValues));
        console.log('As stringified:', JSON.stringify(this.checkboxResponseValues));
    }
    handleAdditionalInfoResponseChange(event){
        this.additionalInfoResponseId = event.target.dataset.id;
        this.additionalInfoValue = event.target.value;
        //console.log(this.additionalInfoResponseId);
        //console.log(this.additionalInfoValue);
    }
    saveRecords(){
        if(this.radioResponseValues.length > 0){
            updateResponseChoiceForRadioType({responseList : this.radioResponseValues})
            .then(result => {
                console.log()});
                this.radioResponseValues = [];
        }
        if(this.textResponseValues.length > 0){
            updateResponseChoiceForTextType({responseList : this.textResponseValues})
            .then(result => {
                //console.log('SAVE',result)
                });
                this.textResponseValues = [];
        }
        if (this.checkboxResponseValues.length > 0){
            updateResponseChoiceForCheckboxType({responseTrueList : this.checkboxTrueResponseValues, responseFalseList : this.checkboxFalseResponseValues, responseIdList : this.currentScreenResponseIds})
            .then(result => {
                //console.log('SAVE',JSON.stringify(result))
                });
                this.checkboxTrueResponseValues = [];
                this.checkboxFalseResponseValues = [];
                this.checkboxResponseValues = [];
                this.currentScreenResponseIds = [];
        }

        if(this.additionalInfoResponseId && this.additionalInfoValue) {
            updateResponseChoiceForAdditionalInfo({
                responseId: this.additionalInfoResponseId,
                additionalInfo: this.additionalInfoValue
            })
            .then(result => {
                console.log('SAVE',JSON.stringify(result))
                // clear after save
                this.additionalInfoResponseId = '';
                this.additionalInfoValue = '';
            })
            .catch(error => {
                console.error('Error saving additional info', error);
            });
        }

                //for logo starts
        if(this.fileData && this.fileData.base64){
            console.log('In the fileData and Base64 line 428');
            this.isLoading = true;
            if (this.isLoading){
                console.log('Test ', this.fileData.base64);
                console.log('Test ', this.fileData.fileName);
                this.isLoading = false;
                //this.isUploading = true;
                UploadCompanyLogo({
                    base64: this.fileData.base64,
                    filename: this.fileData.fileName,
                    companyLogoId: this.projectId
                }).then(result =>{
                    if (result) {
                        console.log('Image Saved===', result);
                   
                     //Immediately fetch latest image URL
                        return getFileUrl({ recordId: this.projectId });
                    }

                setTimeout(() => {
                getFileUrl({ recordId: this.projectId })
                .then(url => {
                    if (url) {
                            //this.savedImageUrl = url + '?t=' + new Date().getTime(); // prevent cache
                        this.savedImageUrl = url;
                        console.log('New Image URL===', this.savedImageUrl);
                        this.imagePreview = ''; // clear preview
                    }
                    })
                .catch(err => console.error(err));
                        }, 1000);
                    });
            
            }
        }
    }

    saveCurrentOnLoadSequenceForNext(seq){
        saveCurrentSequenceNext({intakeId : this.projectId, currentSequence: seq})
            .then(result => {
                result.forEach(res => {
                    console.log('Id:', res.Id, 'Current Sequence:', res.Current_Sequence__c, 'Current Field:', res.Current_Field__c);
                });
                
                //console.log('sequence', JSON.stringify(result))
            })
        Promise.resolve().then(() => {
            this.resetSelectedSection();
            this.saveRecords();
            this.loadSectionByScreen();
            this.getOnboardingProgress();
            this.getSectionProgress();

            const nextButtonSelected = this.template.querySelector(`button[data-id="${this.sectionId}"]`);
            if (nextButtonSelected) {
                nextButtonSelected.classList.add('sidebar-button-selected');
            }
        }); 
    }

    saveCurrentOnLoadSequenceForBack(seq){
        saveCurrentSequenceBack({intakeId : this.projectId, sectionId : this.sectionId, currentSequence: seq, currentField : this.currentScreen})
            .then(result => {
                result.forEach(res => {
                    console.log('Id:', res.Id, 'Current Sequence:', res.Current_Sequence__c, 'Current Field:', res.Current_Field__c);
                });
                
                //console.log('sequence', JSON.stringify(result))
            })
        Promise.resolve().then(() => {
            this.resetSelectedSection();
            this.saveRecords();
            this.loadSectionByScreen();
            this.getOnboardingProgress();
            this.getSectionProgress();

            const nextButtonSelected = this.template.querySelector(`button[data-id="${this.sectionId}"]`);
            if (nextButtonSelected) {
                nextButtonSelected.classList.add('sidebar-button-selected');
            }
        }); 
    }

    saveCurrentOnLoadField(){
        saveCurrentField({sectionId : this.currentSection, intakeId : this.projectId, currentField : this.currentScreen})
        .then(result =>{
            console.log('field',result);
            console.log('aaaa9999999999999999');
        })
    }

    handleResume(){
        this.showFinishLater = false;
        this.connectedCallback();
        this.showIntakeContainer = true;
    }
}