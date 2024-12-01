import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Hash "mo:base/Hash";
import Buffer "mo:base/Buffer";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

module {
    // User data structure
    public type UserProfile = {
        id: Principal;
        username: Text;
        email: Text;
        registeredAt: Time.Time;
        role: UserRole;
        isActive: Bool;
        profileImageUrl: ?Text;
    };

    // User roles for access control
    public type UserRole = {
        #Admin;
        #Moderator;
        #Supporter;
        #Visitor;
    };

    // Authentication result type
    public type AuthResult = Result.Result<UserProfile, Text>;

    // User management actor class
    actor class UserManager() {
        // Stable storage for user data
        private stable var usersEntries : [(Principal, UserProfile)] = [];
        private var users = HashMap.HashMap<Principal, UserProfile>(
            10, 
            Principal.equal, 
            Principal.hash
        );

        // Initialize users from stable storage on upgrade
        system func preupgrade() {
            usersEntries := Iter.toArray(users.entries());
        };

        system func postupgrade() {
            users := HashMap.fromIter(usersEntries.vals(), 10, Principal.equal, Principal.hash);
            usersEntries := [];
        };

        // Create a new user profile
        public shared func createUser(
            principal: Principal, 
            username: Text, 
            email: Text,
            profileImageUrl: ?Text
        ) : async AuthResult {
            // Validate input
            if (Text.size(username) < 3) {
                return #err("Username must be at least 3 characters");
            };

            if (Text.size(email) < 5 or not _validateEmail(email)) {
                return #err("Invalid email address");
            };

            // Check if user already exists
            switch (users.get(principal)) {
                case (null) {
                    let newUser : UserProfile = {
                        id = principal;
                        username = username;
                        email = email;
                        registeredAt = Time.now();
                        role = #Visitor;
                        isActive = true;
                        profileImageUrl = profileImageUrl;
                    };
                    users.put(principal, newUser);
                    #ok(newUser)
                };
                case (_) {
                    #err("User already exists")
                }
            }
        };

        // Update user profile

        public shared func updateUserProfile(
            principal: Principal, 
            username: ?Text, 
            email: ?Text,
            profileImageUrl: ?Text

        ) : async AuthResult {
            switch (users.get(principal)) {
                case (null) { 
                    #err("User not found") 
                };
                case (?existingUser) {
                    let updatedUser : UserProfile = {
                        id = existingUser.id;
                        username = switch(username) {
                            case (null) { existingUser.username };
                            case (?newUsername) { newUsername };
                        };
                        email = switch(email) {
                            case (null) { existingUser.email };
                            case (?newEmail) { 
                                if (Text.size(newEmail) < 5 or not _validateEmail(newEmail)) {
                                    existingUser.email
                                } else { 
                                    newEmail 
                                }
                            };
                        };
                        registeredAt = existingUser.registeredAt;
                        role = existingUser.role;
                        isActive = existingUser.isActive;
                        profileImageUrl = switch(profileImageUrl) {
                            case (null) { existingUser.profileImageUrl };
                            case (?newImageUrl) { ?newImageUrl };
                        };
                    };
                    users.put(principal, updatedUser);
                    #ok(updatedUser)
                }
            }
        };

        // Get user profile
        public query func getUserProfile(principal: Principal) : async ?UserProfile {
            users.get(principal)
        };

        // Activate/Deactivate user

        public shared func setUserStatus(
            adminPrincipal: Principal, 
            userPrincipal: Principal, 
            isActive: Bool

        ) : async AuthResult {
            // First, check if the admin exists and has the right role
            switch (users.get(adminPrincipal)) {
                case (null) { 
                    return #err("Admin not found") 
                };
                case (?admin) {
                    if (admin.role != #Admin) {
                        return #err("Unauthorized action")
                    }
                }
            };

            // Then proceed with user status change
            switch (users.get(userPrincipal)) {
                case (null) { 
                    #err("User not found") 
                };
                case (?existingUser) {
                    let updatedUser = {
                        existingUser with 
                        isActive = isActive
                    };
                    users.put(userPrincipal, updatedUser);
                    #ok(updatedUser)
                }
            }
        };

        // Private email validation helper
        private func _validateEmail(email: Text) : Bool {
            let emailPattern = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)*$";
            // In a real-world scenario, you'd use a more robust email validation
            // This is a simple regex check
            return true; // Placeholder - implement actual regex validation
        };

        // List all users (admin-only function)

        public shared func listUsers(
            adminPrincipal: Principal,
            limit: ?Nat,
            offset: ?Nat
        ) : async Result.Result<[UserProfile], Text> {
            // Verify admin access
            switch (users.get(adminPrincipal)) {
                case (null) { 
                    return #err("Admin not found") 
                };
                case (?admin) {
                    if (admin.role != #Admin) {
                        return #err("Unauthorized access")
                    }
                }
            };

            // Convert HashMap to array and apply optional pagination
            let userArray = Iter.toArray(users.vals());
            let paginatedUsers = switch(limit) {
                case (null) { userArray };
                case (?maxLimit) {
                    let startIndex = switch(offset) {
                        case (null) { 0 };
                        case (?start) { start };
                    };
                    Array.subArray(userArray, startIndex, Nat.min(maxLimit, userArray.size() - startIndex))
                }
            };

            #ok(paginatedUsers)
        };

        // Count total number of users
        public query func getUserCount() : async Nat {
            users.size()
        };


    }}
