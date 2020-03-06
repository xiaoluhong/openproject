import {CardClickHandler} from "core-components/wp-card-view/event-handler/click-handler";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {States} from "core-components/states.service";
import {IFCViewerService} from "core-app/modules/bim/ifc_models/ifc-viewer/ifc-viewer.service";
import {BcfApiService} from "core-app/modules/bim/bcf/api/bcf-api.service";
import {BcfViewpointPaths} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.paths";

export class BcfClickHandler extends CardClickHandler {
  @InjectField() viewer:IFCViewerService;
  @InjectField() states:States;
  @InjectField() bcfApi:BcfApiService;

  protected handleWorkPackage(wpId:string, element:JQuery<HTMLElement>, evt:JQuery.TriggeredEvent) {
    this.setSelection(wpId, element, evt);
    const wp = this.states.workPackages.get(wpId).value!;

    const current = this.viewer.saveBCFViewpoint() as any;
    delete current.snapshot;
    console.warn(JSON.stringify(current));


    // Open the viewpoint if any
    if (this.viewer.viewerVisible() && wp.bcfViewpoints) {
      const first = wp.bcfViewpoints[0].href;
      const resource = this.bcfApi.parse(first) as BcfViewpointPaths;
      resource
        .get()
        .subscribe((viewpoint) => {
          this.viewer.loadBCFViewpoint(viewpoint);
        });
    }
  }
}
