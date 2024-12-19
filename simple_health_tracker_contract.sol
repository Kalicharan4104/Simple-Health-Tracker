// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HealthTracker {
    // Struct to represent a health record
    struct HealthRecord {
        uint256 timestamp;
        uint256 weight;
        uint256 bloodPressureSystolic;
        uint256 bloodPressureDiastolic;
        uint256 heartRate;
        uint256 bloodSugar;
        string additionalNotes;
        bool isVerified;
    }

    // Struct for user profile
    struct UserProfile {
        address userAddress;
        string name;
        uint256 age;
        string gender;
        uint256 height;
        bool isRegistered;
    }

    // Mapping to store user profiles
    mapping(address => UserProfile) public userProfiles;

    // Mapping to store health records for each user
    mapping(address => HealthRecord[]) public healthRecords;

    // Mapping for healthcare professional access
    mapping(address => mapping(address => bool)) public professionalAccess;

    // Events to log important actions
    event UserRegistered(address indexed user, string name);
    event HealthRecordAdded(address indexed user, uint256 timestamp);
    event HealthRecordVerified(address indexed user, uint256 recordIndex);
    event ProfessionalAccessGranted(address indexed user, address indexed professional);
    event ProfessionalAccessRevoked(address indexed user, address indexed professional);

    // Modifiers
    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    modifier onlyAuthorizedProfessional(address _user) {
        require(
            professionalAccess[_user][msg.sender] || 
            msg.sender == _user, 
            "Not authorized to access records"
        );
        _;
    }

    // User Registration
    function registerUser(
        string memory _name, 
        uint256 _age, 
        string memory _gender, 
        uint256 _height
    ) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        
        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            name: _name,
            age: _age,
            gender: _gender,
            height: _height,
            isRegistered: true
        });

        emit UserRegistered(msg.sender, _name);
    }

    // Add Health Record
    function addHealthRecord(
        uint256 _weight,
        uint256 _bloodPressureSystolic,
        uint256 _bloodPressureDiastolic,
        uint256 _heartRate,
        uint256 _bloodSugar,
        string memory _additionalNotes
    ) public onlyRegisteredUser {
        HealthRecord memory newRecord = HealthRecord({
            timestamp: block.timestamp,
            weight: _weight,
            bloodPressureSystolic: _bloodPressureSystolic,
            bloodPressureDiastolic: _bloodPressureDiastolic,
            heartRate: _heartRate,
            bloodSugar: _bloodSugar,
            additionalNotes: _additionalNotes,
            isVerified: false
        });

        healthRecords[msg.sender].push(newRecord);

        emit HealthRecordAdded(msg.sender, block.timestamp);
    }

    // Verify Health Record (by healthcare professional)
    function verifyHealthRecord(
        address _user, 
        uint256 _recordIndex
    ) public {
        require(
            professionalAccess[_user][msg.sender], 
            "Not authorized to verify records"
        );
        require(
            _recordIndex < healthRecords[_user].length, 
            "Invalid record index"
        );

        healthRecords[_user][_recordIndex].isVerified = true;

        emit HealthRecordVerified(_user, _recordIndex);
    }

    // Grant Access to Healthcare Professional
    function grantProfessionalAccess(address _professional) public onlyRegisteredUser {
        professionalAccess[msg.sender][_professional] = true;

        emit ProfessionalAccessGranted(msg.sender, _professional);
    }

    // Revoke Access from Healthcare Professional
    function revokeProfessionalAccess(address _professional) public onlyRegisteredUser {
        professionalAccess[msg.sender][_professional] = false;

        emit ProfessionalAccessRevoked(msg.sender, _professional);
    }

    // Get User Profile
    function getUserProfile() public view onlyRegisteredUser returns (UserProfile memory) {
        return userProfiles[msg.sender];
    }

    // Get Health Records
    function getHealthRecords() 
        public 
        view 
        onlyAuthorizedProfessional(msg.sender) 
        returns (HealthRecord[] memory) 
    {
        return healthRecords[msg.sender];
    }

    // Get Specific Health Record
    function getHealthRecordByIndex(
        address _user, 
        uint256 _index
    ) 
        public 
        view 
        onlyAuthorizedProfessional(_user) 
        returns (HealthRecord memory) 
    {
        require(_index < healthRecords[_user].length, "Invalid record index");
        return healthRecords[_user][_index];
    }

    // Calculate Health Metrics
    function calculateBMI(address _user) public view returns (uint256) {
        UserProfile memory profile = userProfiles[_user];
        
        // Check if user has records and is registered
        require(profile.isRegistered, "User not registered");
        require(healthRecords[_user].length > 0, "No health records found");

        // Get the latest weight record
        HealthRecord memory latestRecord = healthRecords[_user][healthRecords[_user].length - 1];
        
        // Calculate BMI (weight in kg / (height in meters)^2)
        // Assume weight is in kg and height is in cm
        uint256 bmi = (latestRecord.weight * 10000) / (profile.height * profile.height);
        
        return bmi;
    }

    // Fallback function
    receive() external payable {
        revert("Direct sends not allowed");
    }
}