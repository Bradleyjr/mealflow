import Foundation

public enum HouseholdRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case owner
    case member

    public var id: String { rawValue }
}

public struct HouseholdMember: Identifiable, Codable, Hashable, Sendable {
    public var id: String { userID }
    public var userID: String
    public var displayName: String
    public var role: HouseholdRole
    public var joinedDate: Date

    public init(userID: String, displayName: String, role: HouseholdRole, joinedDate: Date = .now) {
        self.userID = userID
        self.displayName = displayName
        self.role = role
        self.joinedDate = joinedDate
    }
}

public struct Household: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var members: [HouseholdMember]
    public var sharedRecipeIDs: [UUID]
    public var inviteCode: String

    public init(
        id: UUID = UUID(),
        name: String,
        members: [HouseholdMember] = [],
        sharedRecipeIDs: [UUID] = [],
        inviteCode: String
    ) {
        self.id = id
        self.name = name
        self.members = members
        self.sharedRecipeIDs = sharedRecipeIDs
        self.inviteCode = inviteCode
    }
}

public enum HouseholdService {
    public static func generateInviteCode(length: Int = 6) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).map { _ in alphabet.randomElement()! })
    }
}
