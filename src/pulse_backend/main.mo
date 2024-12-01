import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Int "mo:base/Int";

module {
    // User profile structure
    public type UserProfile = {
        id: Principal;
        username: ?Text;
        email: ?Text;
        fullName: ?Text;
        bio: ?Text;
        avatarUrl: ?Text;
        createdAt: Int;
        updatedAt: Int;
        isAdmin: Bool;
    };

    // User registration error types
    public type UserRegistrationError = {
        #AlreadyExists;
        #InvalidInput;
        #UnauthorizedRegistration;
    };

    // User update error types
    public type UserUpdateError = {
        #UserNotFound;
        #UnauthorizedUpdate;
        #InvalidInput;
    };

    // User management actor class
    public class UserManager() {
        // Internal storage for user profiles
        let userProfiles = HashMap.HashMap<Principal, UserProfile>(
            10, 
            Principal.equal, 
            Principal.hash
        );

        // Create a new user profile
        public func registerUser(
            userId: Principal, 
            username: ?Text, 
            email: ?Text, 
            fullName: ?Text,
            isAdmin: Bool
        ) : Result.Result<UserProfile, UserRegistrationError> {
            // Validate input
            if (Option.isNull(username) and Option.isNull(email)) {
                return #err(#InvalidInput);
            };

            // Check if user already exists
            switch (userProfiles.get(userId)) {
                case (null) {
                    let newProfile : UserProfile = {
                        id = userId;
                        username = username;
                        email = email;
                        fullName = fullName;
                        bio = null;
                        avatarUrl = null;
                        createdAt = Int.abs(Time.now());
                        updatedAt = Int.abs(Time.now());
                        isAdmin = isAdmin;
                    };
                    
                    userProfiles.put(userId, newProfile);
                    #ok(newProfile)
                };
                case (_) {
                    #err(#AlreadyExists)
                }
            }
        };

        // Update user profile
        public func updateUserProfile(
            userId: Principal, 
            username: ?Text,
            email: ?Text,
            fullName: ?Text,
            bio: ?Text,
            avatarUrl: ?Text
        ) : Result.Result<UserProfile, UserUpdateError> {
            switch (userProfiles.get(userId)) {
                case (null) {
                    #err(#UserNotFound)
                };
                case (?existingProfile) {
                    let updatedProfile : UserProfile = {
                        id = existingProfile.id;
                        username = username or existingProfile.username;
                        email = email or existingProfile.email;
                        fullName = fullName or existingProfile.fullName;
                        bio = bio or existingProfile.bio;
                        avatarUrl = avatarUrl or existingProfile.avatarUrl;
                        createdAt = existingProfile.createdAt;
                        updatedAt = Int.abs(Time.now());
                        isAdmin = existingProfile.isAdmin;
                    };
                    
                    userProfiles.put(userId, updatedProfile);
                    #ok(updatedProfile)
                }
            }
        };

        // Get user profile
        public func getUserProfile(userId: Principal) : ?UserProfile {
            userProfiles.get(userId)
        };

        // List all users (admin only)
        public func listUsers(caller: Principal) : Result.Result<[UserProfile], Text> {
            // Check if caller is admin
            switch (userProfiles.get(caller)) {
                case (null) { #err("Unauthorized") };
                case (?profile) {
                    if (not profile.isAdmin) {
                        return #err("Unauthorized");
                    };
                    
                    let userList = Buffer.Buffer<UserProfile>(userProfiles.size());
                    for (user in userProfiles.vals()) {
                        userList.add(user);
                    };
                    
                    #ok(userList.toArray())
                }
            }
        };

        // Delete user profile
        public func deleteUser(
            userId: Principal, 
            caller: Principal
        ) : Result.Result<(), UserUpdateError> {
            // Check if caller is the user or an admin
            switch (userProfiles.get(caller)) {
                case (null) { #err(#UnauthorizedUpdate) };
                case (?callerProfile) {
                    if (not (caller == userId or callerProfile.isAdmin)) {
                        return #err(#UnauthorizedUpdate);
                    };
                    
                    switch (userProfiles.get(userId)) {
                        case (null) { #err(#UserNotFound) };
                        case (_) {
                            userProfiles.delete(userId);
                            #ok()
                        }
                    }
                }
            }
        };

        // Check if user exists
        public func userExists(userId: Principal) : Bool {
            Option.isSome(userProfiles.get(userId))
        };
    };
}