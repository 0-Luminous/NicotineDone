//
//  Persistence.swift
//  CigTrack
//
//  Created by Yan on 4/11/25.
//

import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PuffQuest")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved error \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension PersistenceController {
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext

        let user = User(context: ctx)
        user.id = UUID()
        user.createdAt = Date()
        user.productType = ProductType.cigarettes.rawValue
        user.dailyLimit = 10
        user.packSize = 20
        user.packCost = 12.5
        user.currencyCode = "USD"
        user.coins = 25
        user.xp = 420

        let streak = Streak(context: ctx)
        streak.id = UUID()
        streak.currentLength = 3
        streak.bestLength = 5
        streak.updatedAt = Date()
        streak.user = user

        (0..<7).forEach { dayOffset in
            let stat = DailyStat(context: ctx)
            stat.id = UUID()
            stat.date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            stat.count = Int32(5 + dayOffset)
            stat.type = EntryType.cig.rawValue
            stat.user = user
        }

        do {
            try ctx.save()
        } catch {
            fatalError("Preview context error \(error)")
        }
        return controller
    }()
}

extension NSManagedObjectContext {
    func saveIfNeeded() {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            assertionFailure("Failed to save context: \(error)")
        }
    }
}
