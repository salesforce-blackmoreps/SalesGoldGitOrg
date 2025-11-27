import { LightningElement,api } from 'lwc';
import myLogo from '@salesforce/resourceUrl/myLogo';
import { getRecord } from 'lightning/uiRecordApi';
import getSections from '@salesforce/apex/Test_BMA_AccelerateController.getSections';
import getSecttionDetail from '@salesforce/apex/Test_BMA_AccelerateController.getSecttionDetail';
import updateResponseChoiceForRadioType from '@salesforce/apex/Test_BMA_AccelerateController.updateResponseChoiceForRadioType';
import updateResponseChoiceForCheckboxType from '@salesforce/apex/Test_BMA_AccelerateController.updateResponseChoiceForCheckboxType';
import updateResponseChoiceForTextType from '@salesforce/apex/Test_BMA_AccelerateController.updateResponseChoiceForTextType';
import saveCurrentSequence from '@salesforce/apex/Test_BMA_AccelerateController.saveCurrentSequence';
import saveCurrentField from '@salesforce/apex/Test_BMA_AccelerateController.saveCurrentField';
import UploadCompanyLogo from '@salesforce/apex/Test2_BMA_AccelerateController.UploadCompanyLogo';
import getFileUrl from '@salesforce/apex/Test2_BMA_AccelerateController.getFileUrl';

import BMAComponentHelpText from '@salesforce/resourceUrl/BMAComponentHelpText';

export default class Bma_OpptoClose extends LightningElement {
    recordId = 'a0sO1000003WlWjIAK';
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
    @api projectId ; //= 'a0tO100000OjuBVIAZ'

    sections = [];
    completedSections = [];
    imageURL = myLogo;
    responses = [];
    currentSection = '';
    currentScreen = '';
    currentSectionScreenCount = 1;
    currentSectionOnScreen    = 1;
    sectionId = '';
    firstSectionId = '';
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
    currentScreenResponseIds = [];
    showFinishLater = false;
    showIntakeContainer = true;

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
        //console.log(this.recordId);
        //for logo
        this.loadSavedImage();
        this.loadComponentData();
    } 



     async openHelp() {
        try {
            const response = await fetch(BMAComponentHelpText);
            this.helpText = await response.text();
            this.showModal = true;   // show modal with text
        } catch (error) {
            console.error('Error loading help text:', error);
        }
    }

    closeModal() {
        this.showModal = false;
    }



    loadComponentData(){
        getSections({ intakeId: this.recordId })
        .then(result => {
            //console.log(result.sections);            
            //for(let i=0;i<result.sections.lenght;i++){
            this.sections = result.sections;
            console.log('this.sections',this.sections);

            this.sections.forEach(section => {
                this.totalScreenCount += section.screenCount;
                if(section.Sequence == section.currentSequence){
                    this.sectionId = section.Id;
                    this.currentSection = section.Id;
                    this.currentSectionScreenCount = section.screenCount || 1;
                    this.currentSectionOnScreen = parseInt(section.currentField) || 1;
                    if(this.currentSectionOnScreen > 1){
                        for(let i=1;i<=this.currentSectionOnScreen;i++){
                            this.totalScreenCompleteCount += 1;
                        }
                    }
                    this.currentScreen = section.currentField;
                    this.resetSelectedSection();
                    Promise.resolve().then(() => {
                        const FirstButton = this.template.querySelector(`button[data-id="${this.sectionId}"]`);
                        if (FirstButton) {
                            FirstButton.classList.add('sidebar-button-selected');
                        }
                    });

                }
                else if(section.Sequence < section.currentSequence){
                    this.totalScreenCompleteCount += section.screenCount;
                    this.completedSections.push(section.Id);
                    console.log('completedSections',JSON.stringify(this.completedSections));
                }
               console.log('a', section.Sequence);
               console.log('b', section.currentSequence);
               console.log('c', section.currentField);
            })
            Promise.resolve().then(() => {
                this.loadSectionByScreen();
                this.grayCompletedSections();
                this.getOnboardingProgress();
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

        //this.currentSectionOnScreen  = 1;  
        this.currentSection = sectionId;
        //this.currentScreen  = '1';
        const savedScreen = this.sectionState[sectionId]?.screen || 1;
        this.currentSectionOnScreen = savedScreen;
        this.currentScreen = savedScreen.toString();

        this.loadSectionByScreen();
        this.resetSelectedSection();
        event.target.classList.add('sidebar-button-selected');

        this.getSectionProgress();
        this.sectionProgressStyle();
    }

    loadSectionByScreen(){
        getSecttionDetail({ sectionId: this.sectionId, intakeId: this.recordId, screen: this.currentScreen})
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
        if(this.currentSectionScreenCount > this.currentSectionOnScreen) {
            this.currentSectionOnScreen += 1;
            this.totalScreenCompleteCount += 1;
            console.log("currentSectionOnScreen" , this.currentSectionOnScreen);
            this.currentScreen = this.currentSectionOnScreen.toString();
            //this.saveCurrentOnLoadField();
            this.sectionState[this.currentSection] = {screen: this.currentSectionOnScreen};

            Promise.resolve().then(() => {
                this.saveCurrentOnLoadField();
                this.saveRecords();
                this.loadSectionByScreen();                
                this.getOnboardingProgress();
                this.getSectionProgress();
            }); 
        }
        else {
            this.saveRecords();
            this.sectionProgressBar = '0.00%';
            const currentSectionIndex = this.sections.findIndex(sec => sec.Id === this.currentSection);
            const nextSection = this.sections[currentSectionIndex + 1];

            if (nextSection) {
                this.totalScreenCompleteCount += 1;
                this.completedSections.push(this.sectionId);
                this.grayCompletedSections(); 

                this.currentSection = nextSection.Id;
                this.sectionId = nextSection.Id;
                this.currentSectionScreenCount = nextSection.screenCount;

                const savedScreen = this.sectionState[nextSection.Id]?.screen || 1;
                this.currentSectionOnScreen = savedScreen;
                this.currentScreen = savedScreen.toString();
                console.log('seq',nextSection.Sequence);

                //this.saveCurrentOnLoadSequence(nextSection.Sequence);
                saveCurrentSequence({intakeId : this.recordId, currentSequence: nextSection.Sequence})
                .then(result => {
                    result.forEach(res => {
                        console.log('Id:', res.Id, 'Current Sequence:', res.Current_Sequence__c, 'Current Field:', res.Current_Field__c);
                    });
                    
                    //console.log('sequence', JSON.stringify(result))
                })
                this.resetSelectedSection();

                const nextButton = this.template.querySelector(`button[data-id="${nextSection.Id}"]`);
                if (nextButton) {
                    nextButton.classList.add('sidebar-button-selected');
                }
              
                Promise.resolve().then(() => {
                    //this.saveRecords();
                    this.loadSectionByScreen();
                    this.getOnboardingProgress();
                    this.getSectionProgress();
                }); 
            } else {
                this.totalScreenCompleteCount += 1;
                this.completedSections.push(this.sectionId);
                this.grayCompletedSections();
                this.resetSelectedSection();
                this.getOnboardingProgress();
                this.getSectionProgress();
                this.sectionProgressStyle();
                this.onboardingProgressStyle();
            }   
        }       
    }

    handleBack(){
        console.log('100000000');
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
        getFileUrl({ recordId: this.recordId })
        .then(url => {
             this.savedImageUrl = url + '#t=' + new Date().getTime();
            //this.savedImageUrl = url;
        })
        .catch(err => console.error(err));
    }
    //logo upload ends

    loadPrevSectionLastScreen(){
        const currentSectionIndex = this.sections.findIndex(sec => sec.Id === this.currentSection);
        const prevSection = this.sections[currentSectionIndex - 1];
        //console.log('currentSectionIndex',JSON.stringify(this.prevSection));
        console.log('prevSections',JSON.stringify(prevSection));
        if(prevSection) {
            console.log('hi1');
            /*this.completedSections = this.completedSections.filter(item => item !== this.sectionId);
            console.log('completedSections',JSON.stringify(this.completedSections));
            this.grayCompletedSections();*/

            this.currentSection = prevSection.Id;
            this.sectionId = prevSection.Id;
            this.currentSectionScreenCount = prevSection.screenCount;
            //this.totalScreenCompleteCount -= 1;

            //const savedScreen = this.sectionState[prevSection.Id]?.screen || 1;
            this.currentSectionOnScreen = prevSection.screenCount;
            this.currentScreen = this.currentSectionOnScreen.toString();
            console.log('hi2');

            //this.saveCurrentOnLoadSequence(prevSection.Sequence);

            /*saveCurrentSequence({intakeId : this.recordId, currentSequence: prevSection.Sequence})
            .then(result => {
                result.forEach(res => {
                    console.log('Id:', res.Id, 'Current Sequence:', res.Current_Sequence__c, 'Current Field:', res.Current_Field__c);
                });
            })*/

            this.resetSelectedSection();

            const prevButton = this.template.querySelector(`button[data-id="${prevSection.Id}"]`);
            
            if (prevButton) {
                prevButton.classList.add('sidebar-button-selected');
                console.log('prevButton',prevButton);
            }

            Promise.resolve().then(() => { 
                this.loadSectionByScreen();
                //this.getOnboardingProgress();
                this.getSectionProgress();
            });
        }

    }

    loadSameSectionPrevScreen(){
        this.currentSectionOnScreen -= 1;
        this.totalScreenCompleteCount -= 1;
        console.log("currentSectionOnScreen" , this.currentSectionOnScreen);
        this.currentScreen = this.currentSectionOnScreen.toString();
        //this.saveCurrentOnLoadField();
        this.sectionState[this.currentSection] = {screen: this.currentSectionOnScreen};
        Promise.resolve().then(() => {
            this.loadSectionByScreen();
            //this.getOnboardingProgress();
            this.getSectionProgress();
        }); 
    }

    handleFinishLater(){        
        this.showFinishLater = true;
        this.showIntakeContainer = false;
    }
    
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
        if (!this.onboardingProgressComplete){
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
                console.log('SAVE',result)});
                this.textResponseValues = [];
        }
        if (this.checkboxResponseValues.length > 0){
            updateResponseChoiceForCheckboxType({responseTrueList : this.checkboxTrueResponseValues, responseFalseList : this.checkboxFalseResponseValues, responseIdList : this.currentScreenResponseIds})
            .then(result => {
                console.log('SAVE',JSON.stringify(result))});
                this.checkboxTrueResponseValues = [];
                this.checkboxFalseResponseValues = [];
                this.checkboxResponseValues = [];
                this.currentScreenResponseIds = [];
        }
                //for logo starts
        /*if(this.fileData && this.fileData.base64){

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
                    companyLogoId: this.recordId
                }).then(result =>{
                    if (result) {
                        console.log('Image Saved===', result);
                   
                     //Immediately fetch latest image URL
                        return getFileUrl({ recordId: this.recordId });
                    }

                setTimeout(() => {
                getFileUrl({ recordId: this.recordId })
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
        }*/
    }

    saveCurrentOnLoadSequence(seq){
        saveCurrentSequence({intakeId : this.recordId, currentSequence: seq})
                .then(result => {
                    result.forEach(res => {
                        console.log('Id:', res.Id, 'Current Sequence:', res.Current_Sequence__c, 'Current Field:', res.Current_Field__c);
                    });
                    
                    //console.log('sequence', JSON.stringify(result))
                })
    }

    saveCurrentOnLoadField(){
        saveCurrentField({sectionId : this.currentSection, intakeId : this.recordId, currentField : this.currentScreen})
        .then(result =>{
            console.log('field',result);
        })
    }

    handleResume(){
        this.showFinishLater = false;
        this.connectedCallback();
        this.showIntakeContainer = true;
    }
   
}