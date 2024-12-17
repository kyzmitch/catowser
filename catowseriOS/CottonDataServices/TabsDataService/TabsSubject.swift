//
//  TabsSubject.swift
//  CottonDataServices
//
//  Created by Andrei Ermoshin on 5/30/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

/// Tabs subject is an object which holds an array of observers
/// and uses them to notify about specific changes.
/// 
/// The detach function is not needed now, since the moment
/// when subject started to store observers by weak references.
public protocol TabsSubject: Sendable {
    /// Add tabs observer. Notifies the new observer right away with existing data if needed.
    /// - Parameter observer: A new observer to notify from this subject
    /// - Parameter notify: Tells if newly added observer needs to be notified right away
    func attach(_ observer: TabsObserver, notify: Bool) async
}
