import { ElementRef, Inject, ChangeDetectorRef, ViewChild, Directive } from "@angular/core";
import {OpModalComponent} from "app/components/op-modals/op-modal.component";
import {OpModalLocalsToken} from "app/components/op-modals/op-modal.service";
import {OpModalLocalsMap} from "app/components/op-modals/op-modal.types";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {TimeEntryFormComponent} from "core-app/modules/time_entries/form/form.component";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

@Directive()
export abstract class TimeEntryBaseModal extends OpModalComponent {
  @ViewChild('editForm', { static: true }) editForm:TimeEntryFormComponent;

  public text:{ [key:string]:string } = {
    title: this.i18n.t('js.time_entry.label'),
    cancel: this.i18n.t('js.button_cancel'),
    close: this.i18n.t('js.button_close'),
    delete: this.i18n.t('js.button_delete'),
    areYouSure: this.i18n.t('js.text_are_you_sure'),
  };

  public closeOnEscape = false;
  public closeOnOutsideClick = false;

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) readonly locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly i18n:I18nService) {
    super(locals, cdRef, elementRef);
  }

  public abstract setModifiedEntry($event:{savedResource:HalResource, isInital:boolean}):void;

  public get entry() {
    return this.locals.entry;
  }

  public saveEntry() {
    this.editForm.save()
      .then(() => {
        this.service.close();
      });
  }

  public get saveText() {
    return this.i18n.t('js.button_save');
  }

  public get saveAllowed() {
    return true;
  }

  public get deleteAllowed() {
    return true;
  }
}
