// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {Component, ElementRef, EventEmitter, Injector, Input, OnDestroy, OnInit, Optional, Output} from '@angular/core';
import {StateService, Transition, TransitionService} from '@uirouter/core';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {EditableAttributeFieldComponent} from 'core-app/modules/fields/edit/field/editable-attribute-field.component';
import {input} from 'reactivestates';
import {filter, map, take} from 'rxjs/operators';
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {
  activeFieldClassName,
  activeFieldContainerClassName,
  EditForm
} from "core-app/modules/fields/edit/edit-form/edit-form";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {EditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler";
import {EditingPortalService} from "core-app/modules/fields/edit/editing-portal/editing-portal-service";
import {EditFormRoutingService} from "core-app/modules/fields/edit/edit-form/edit-form-routing.service";

@Component({
  selector: 'edit-form,[edit-form]',
  template: '<ng-content></ng-content>'
})
export class EditFormComponent extends EditForm<HalResource> implements OnInit, OnDestroy {
  @Input('resource') resource:HalResource;
  @Input('inEditMode') initializeEditMode:boolean = false;
  @Input('skippedFields') skippedFields:string[] = [];

  @Output('onSaved') onSavedEmitter = new EventEmitter<{ savedResource:HalResource, isInitial:boolean }>();

  public fields:{ [attribute:string]:EditableAttributeFieldComponent } = {};
  private registeredFields = input<string[]>();
  private unregisterListener:Function;

  constructor(public readonly injector:Injector,
              protected readonly elementRef:ElementRef,
              protected readonly $transitions:TransitionService,
              protected readonly ConfigurationService:ConfigurationService,
              protected readonly editingPortalService:EditingPortalService,
              protected readonly $state:StateService,
              protected readonly I18n:I18nService,
              @Optional() protected readonly editFormRouting:EditFormRoutingService) {
    super(injector);

    const confirmText = I18n.t('js.work_packages.confirm_edit_cancel');
    const requiresConfirmation = ConfigurationService.warnOnLeavingUnsaved();

    this.unregisterListener = $transitions.onBefore({}, (transition:Transition) => {
      if (!this.editing) {
        return undefined;
      }

      // Show confirmation message when transitioning to a new state
      // that's not within the edit mode.
      if (!this.editFormRouting || this.editFormRouting.blockedTransition(transition)) {
        if (requiresConfirmation && !window.confirm(confirmText)) {
          return false;
        }

        this.stop();
      }

      return true;
    });
  }

  ngOnDestroy() {
    this.destroy();
  }

  ngOnInit() {
    this.editMode = this.initializeEditMode;

    if (this.initializeEditMode) {
      this.start();
    }
  }

  destroy() {
    this.unregisterListener();
    super.destroy();
  }

  public async activateField(form:EditForm, schema:IFieldSchema, fieldName:string, errors:string[]):Promise<EditFieldHandler> {
    return this.waitForField(fieldName).then((ctrl) => {
      ctrl.setActive(true);
      const container = ctrl.editContainer.nativeElement;
      return this.editingPortalService.create(
        container,
        this.injector,
        form,
        schema,
        fieldName,
        errors
      );
    });
  }

  public async reset(fieldName:string, focus:boolean = false) {
    const ctrl = await this.waitForField(fieldName);
    ctrl.reset();
    ctrl.deactivate(focus);
  }

  public onSaved(isInitial:boolean, saved:HalResource) {
    super.onSaved(isInitial, saved);
    this.stopEditingAndLeave(saved, isInitial);
  }

  public requireVisible(fieldName:string):Promise<void> {
    return new Promise<void>((resolve, _) => {
      const interval = setInterval(() => {
        const field = this.fields[fieldName];

        if (field !== undefined) {
          clearInterval(interval);
          resolve();
        }
      }, 50);
    });
  }

  public get editing():boolean {
    return this.editMode || this.hasActiveFields();
  }

  public register(field:EditableAttributeFieldComponent) {
    this.fields[field.fieldName] = field;
    this.registeredFields.putValue(_.keys(this.fields));

    const shouldActivate =
      (this.editMode && !this.skipField(field) || this.activeFields[field.fieldName]);

    if (shouldActivate) {
      field.activateOnForm(true);
    }
  }

  public waitForField(name:string):Promise<EditableAttributeFieldComponent> {
    return this.registeredFields
      .values$()
      .pipe(
        filter(keys => keys.indexOf(name) >= 0),
        take(1),
        map(() => this.fields[name])
      )
      .toPromise();
  }

  public start() {
    _.each(this.fields, ctrl => this.activate(ctrl.fieldName));
  }

  public stop() {
    this.editMode = false;
    this.closeEditFields();
    this.halEditing.stopEditing(this.resource);
    this.destroy();
  }

  public save() {
    const isInitial = this.resource.isNew;
    return this
      .submit()
      .then((savedResource:HalResource) => {
        this.stopEditingAndLeave(savedResource, isInitial);
      });
  }

  public stopEditingAndLeave(savedResource:HalResource, isInitial:boolean) {
    this.stop();
    this.onSavedEmitter.emit({savedResource, isInitial});
  }

  protected focusOnFirstError():void {
    // Focus the first field that is erroneous
    jQuery(this.elementRef.nativeElement)
      .find(`.${activeFieldContainerClassName}.-error .${activeFieldClassName}`)
      .first()
      .trigger('focus');
  }

  private skipField(field:EditableAttributeFieldComponent) {
    const fieldName = field.fieldName;

    const isSkipField = this.skippedFields.indexOf(fieldName) !== -1;

    // Only skip status or type
    if (!isSkipField) {
      return false;
    }

    // Only skip if value present and not changed in changeset
    const hasDefault = this.resource[fieldName];
    const changed = this.change.changes[fieldName];

    return hasDefault && !changed;
  }
}
