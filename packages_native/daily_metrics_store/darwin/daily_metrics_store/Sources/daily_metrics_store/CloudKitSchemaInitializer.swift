#if DEBUG
    import CoreData
    import Foundation
    import SwiftData

    /// Debug builds only: pushes every attribute of the SwiftData model to
    /// the CloudKit **development** schema, whether or not any record holds
    /// a value in it (#93).
    ///
    /// CloudKit development only adds a field the first time a record is
    /// saved with a value in it, so a schema built up by normal use can be
    /// missing fields, and production (deployed from development) can't add
    /// them at runtime. `initializeCloudKitSchema` creates every record type
    /// and field from the model instead.
    ///
    /// This is the pattern from Apple's "Syncing model data across a
    /// person's devices" (SwiftData), except the store is a throwaway file
    /// in the caches directory, deleted afterwards, rather than the real
    /// store: the schema is pushed from the model, so the local contents
    /// don't matter, and the real store is never touched.
    ///
    /// Slow (tens of seconds, network-bound) and blocking: never call it on
    /// the main thread.
    enum CloudKitSchemaInitializer {
        enum Failure: Error {
            /// No model could be built from the SwiftData types.
            case noModel
            /// The throwaway store didn't load, or CloudKit refused the schema.
            case failed(Error)

            var message: String {
                switch self {
                case .noModel:
                    return "Could not build a Core Data model from DailyMetricRecord"
                case .failed(let error):
                    let error = error as NSError
                    return "\(error.localizedDescription) (\(error.domain) \(error.code)) \(error.userInfo)"
                }
            }
        }

        /// The SwiftData types whose schema is pushed: the store's own list,
        /// so the two can't drift.
        static var modelTypes: [any PersistentModel.Type] { DailyMetricsStore.modelTypes }

        /// Initializes the development schema in `containerIdentifier` and
        /// returns the record types it covers, each as
        /// `{name, fields: [{name, type}]}` using CloudKit's names
        /// (`CD_DailyMetricRecord`, `CD_day`, ...), sorted by name.
        static func run(containerIdentifier: String) throws -> [[String: Any]] {
            guard let model = NSManagedObjectModel.makeManagedObjectModel(for: modelTypes)
            else { throw Failure.noModel }

            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("steady-cloudkit-schema-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }

            do {
                try FileManager.default.createDirectory(
                    at: directory, withIntermediateDirectories: true)
                // An autorelease pool so the container is gone before the
                // files are deleted (Apple's sample does the same).
                try autoreleasepool {
                    let description = NSPersistentStoreDescription(
                        url: directory.appendingPathComponent("schema.store"))
                    description.cloudKitContainerOptions =
                        NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
                    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                    // Load synchronously so the store is ready before the
                    // schema call.
                    description.shouldAddStoreAsynchronously = false

                    let container = NSPersistentCloudKitContainer(
                        name: "SteadySchemaInit", managedObjectModel: model)
                    container.persistentStoreDescriptions = [description]
                    var loadError: Error?
                    container.loadPersistentStores { _, error in loadError = error }
                    if let loadError { throw loadError }

                    try container.initializeCloudKitSchema(options: [])

                    for store in container.persistentStoreCoordinator.persistentStores {
                        try container.persistentStoreCoordinator.remove(store)
                    }
                }
            } catch {
                throw Failure.failed(error)
            }

            return recordTypes(of: model)
        }

        /// The record types and fields Core Data's CloudKit mirroring uses
        /// for `model`: `CD_` + entity and attribute names, plus the
        /// `CD_entityName` field it adds to every record type.
        static func recordTypes(of model: NSManagedObjectModel) -> [[String: Any]] {
            model.entities
                .sorted { ($0.name ?? "") < ($1.name ?? "") }
                .map { entity in
                    var fields = entity.attributesByName.values.map { attribute in
                        ["name": "CD_\(attribute.name)", "type": cloudKitType(attribute.attributeType)]
                    }
                    fields.append(["name": "CD_entityName", "type": "String"])
                    fields.sort { $0["name"]! < $1["name"]! }
                    return ["name": "CD_\(entity.name ?? "?")", "fields": fields]
                }
        }

        /// How CloudKit Console labels the field type an attribute becomes.
        private static func cloudKitType(_ type: NSAttributeType) -> String {
            switch type {
            case .stringAttributeType, .URIAttributeType, .UUIDAttributeType:
                return "String"
            case .integer16AttributeType, .integer32AttributeType, .integer64AttributeType,
                .booleanAttributeType:
                return "Int(64)"
            case .doubleAttributeType, .floatAttributeType:
                return "Double"
            case .dateAttributeType:
                return "Date/Time"
            case .binaryDataAttributeType, .transformableAttributeType:
                return "Bytes"
            default:
                return "other(\(type.rawValue))"
            }
        }
    }
#endif
