//
//  ProjectNotificationsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 19/07/2022.
//

import SwiftUI

struct ProjectNotificationsView: View {
  @Environment(\.presentationMode) var presentationMode
  
  var project: VercelProject
  
  @AppStorage(Preferences.deploymentNotificationIds)
  private var deploymentNotificationIds
  
  @AppStorage(Preferences.deploymentErrorNotificationIds)
  private var deploymentErrorNotificationIds
  
  @AppStorage(Preferences.deploymentReadyNotificationIds)
  private var deploymentReadyNotificationIds
  
  @AppStorage(Preferences.deploymentNotificationsProductionOnly)
  private var deploymentNotificationsProductionOnly
  
  var body: some View {
    let allowDeploymentNotifications = Binding {
      deploymentNotificationIds.contains { $0 == project.id }
    } set: { deploymentNotificationIds.toggleElement(project.id, inArray: $0) }
    
    let allowDeploymentErrorNotifications = Binding {
      deploymentErrorNotificationIds.contains { $0 == project.id }
    } set: { deploymentErrorNotificationIds.toggleElement(project.id, inArray: $0) }
    
    let allowDeploymentReadyNotifications = Binding {
      deploymentReadyNotificationIds.contains { $0 == project.id }
    } set: { deploymentReadyNotificationIds.toggleElement(project.id, inArray: $0) }
    
    let productionNotificationsOnly = Binding {
      deploymentNotificationsProductionOnly.contains { $0 == project.id }
    } set: { deploymentNotificationsProductionOnly.toggleElement(project.id, inArray: $0) }
    
    return Form {
      Section {
        Toggle(isOn: productionNotificationsOnly) {
          Label("Production only", systemImage: "theatermasks.fill")
            .symbolRenderingMode(.hierarchical)
        }
      } footer: {
        Text("When enabled, Zeitgeist will only send the notification types selected below for deployments targeting a production environment.")
      }
      
      Section {
        Toggle(isOn: allowDeploymentNotifications) {
          DeploymentStateIndicator(state: .building)
        }
        
        Toggle(isOn: allowDeploymentErrorNotifications) {
          DeploymentStateIndicator(state: .error)
        }
        
        Toggle(isOn: allowDeploymentReadyNotifications) {
          DeploymentStateIndicator(state: .ready)
        }
      }
    }
    .toolbar {
      Button {
        presentationMode.wrappedValue.dismiss()
      } label: {
        Label("Dismiss", systemImage: "xmark")
          .symbolRenderingMode(.monochrome)
      }
    }
    .navigationTitle("Notifications for \(project.name)")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}

//struct ProjectNotificationsView_Previews: PreviewProvider {
//  static var previews: some View {
//    ProjectNotificationsView()
//  }
//}
