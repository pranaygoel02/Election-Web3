// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ElectionCommission {
    address public electionCommission;
    uint256 public minimumVotingAge;
    address[] public registeredVoters; // Maintain a list of registered voter addresses

    constructor() {
        electionCommission = msg.sender;
    }

    modifier OnlyCommission() {
        require(msg.sender == electionCommission, "OEC");
        _;
    }

    event VoterRegistered(
        uint256 _voterId,
        string _fullName,
        uint256 _dob,
        string _addr,
        uint256 _constituency,
        uint256 _stateId,
        string _faceImageIpfsUrl,
        bool _verified,
        uint256 _phoneNumber,
        uint256 _pinCode,
        uint256 _adhaarNumber
    );
    event PartyCreated(
        uint256 partyId,
        string name,
        string logo,
        string slogan,
        uint256 stateId,
        bool isNationalLevel
    );
    event CandidateAdded(uint256 candidateId, uint256 partyId, uint256 voterId);
    event PartyLeaderAppointed(uint256 partyId, address leader);

    struct Voter {
        uint256 id;
        string fullName;
        uint256 dob;
        string gender;
        string addr;
        uint256 constituency;
        uint256 stateId;
        string faceImageIpfsUrl;
        bool verified;
        uint256 phoneNumber;
        uint256 pinCode;
        uint256 adhaarNumber;
    }

    struct Constituency {
        string name;
    }

    struct State {
        uint256 id;
        string name;
        uint256[] registeredConstituencies;
    }

    struct Party {
        uint256 id;
        string name;
        string logo;
        string slogan;
        address leader;
        uint256 stateId;
        bool isNationalLevel;
    }

    struct Candidate {
        uint256 id;
        uint256 partyId;
        uint256 voterId; // Added voter ID
        string fullName; // Added fullName field
        string faceImageIpfsUrl; // Added faceImageIpfsUrl field
        // uint256 stateId; // Added stateId field
        // uint256 constituencyId; // Added constituency field
        // string constituencyName;
        // string stateName;
        uint256 voteCount;
    }

    mapping(address => Voter) public voters;
    mapping(uint256 => State) public states;
    mapping(uint256 => Constituency) public constituencies;
    mapping(uint256 => Party) public parties;
    mapping(uint256 => Candidate) public candidates;
    uint256 public voterCount; // Added voter count
    uint256 public stateCount;
    uint256 public constituencyCount;
    uint256 public partyCount;
    uint256 public candidateCount;

    function createNewState(string memory _name) external OnlyCommission {
        uint256 newStateId = stateCount;
        states[newStateId].id = newStateId; // Assign the ID
        states[newStateId].name = _name;
        stateCount++;
    }

    function createNewConstituency(
        string memory _name,
        uint256 _stateId
    ) external OnlyCommission {
        require(_stateId < stateCount, "ISID");

        uint256 newConstituencyId = constituencyCount;
        constituencies[newConstituencyId] = Constituency(_name);
        states[_stateId].registeredConstituencies.push(newConstituencyId);
        constituencyCount++;
    }

    function setMinimumVotingAge(uint _age) external OnlyCommission {
        minimumVotingAge = _age;
    }

    function registerVoter(
        string memory _fullName,
        uint256 _dob,
        string memory _gender,
        string memory _addr,
        uint256 _stateId,
        uint256 _constituency,
        string memory _faceImageIpfsUrl,
        uint256 _phoneNumber,
        uint256 _pinCode,
        uint256 _adhaarNumber
    ) external {
        require(msg.sender != electionCommission, "uec");
        require(_stateId < stateCount, "isid");
        require(
            _constituency < states[_stateId].registeredConstituencies.length,
            "icid"
        );

        require(voters[msg.sender].id == 0, "var");

        voters[msg.sender] = Voter(
            voterCount + 1,
            _fullName,
            _dob,
            _gender,
            _addr,
            states[_stateId].registeredConstituencies[_constituency],
            _stateId,
            _faceImageIpfsUrl,
            false,
            _phoneNumber,
            _pinCode,
            _adhaarNumber
        );

        registeredVoters.push(msg.sender); // Add the registered voter address to the list
        emit VoterRegistered(
            voterCount + 1,
            _fullName,
            _dob,
            _addr,
            states[_stateId].registeredConstituencies[_constituency],
            _stateId,
            _faceImageIpfsUrl,
            false,
            _phoneNumber,
            _pinCode,
            _adhaarNumber
        );

        voterCount++; // Increment the voter count
    }

    event VoterVerified(address voterAddres);

    function toggleVerifyVoter(uint256 _voterId) external OnlyCommission {
        address _voterAddress = registeredVoters[_voterId - 1];
        voters[_voterAddress].verified = !voters[_voterAddress].verified;
        emit VoterVerified(_voterAddress);
    }

    function createParty(
        string memory _name,
        string memory _logo,
        string memory _slogan,
        uint256 _stateId,
        bool _isNationalLevel
    ) external OnlyCommission {
        require(_stateId < stateCount, "isid");

        uint256 partyId = partyCount;
        parties[partyId] = Party(
            partyId,
            _name,
            _logo,
            _slogan,
            address(0),
            _stateId,
            _isNationalLevel
        );
        partyCount++;

        emit PartyCreated(
            partyId,
            _name,
            _logo,
            _slogan,
            _stateId,
            _isNationalLevel
        );
    }

    function setPartyLeader(
        uint256 _partyId,
        address _leader
    ) external OnlyCommission {
        require(_partyId < partyCount, "ipid");
        parties[_partyId].leader = _leader;

        emit PartyLeaderAppointed(_partyId, _leader);
    }

    function togglePartyNationalLevel(
        uint256 _partyId,
        bool _isNationalLevel
    ) external OnlyCommission {
        require(_partyId < partyCount, "ipid");

        parties[_partyId].isNationalLevel = _isNationalLevel;
    }

    function addCandidate(
        uint256 _partyId,
        uint256 _voterId
    ) external OnlyCommission {
        require(_partyId < partyCount, "ipid");
        address candidateAddress = registeredVoters[_voterId - 1];
        Voter storage candidateInfo = voters[candidateAddress]; // Fetch the candidate's information from the mapping

        // Ensure the voter is registered and is not already a candidate
        require(candidateInfo.id != 0, "vnr");
        require(candidateInfo.verified, "vnv");

        uint256 candidateId = candidateCount;
        candidates[candidateId] = Candidate(
            candidateId,
            _partyId,
            candidateInfo.id, // Use the stored voterId from the voter's information
            candidateInfo.fullName,
            candidateInfo.faceImageIpfsUrl,
            // candidateInfo.stateId,
            // candidateInfo.constituency,
            // '',
            // '',
            0
        );
        candidateCount++;
        emit CandidateAdded(candidateId, _partyId, candidateInfo.id);
    }

    // Function for a candidate to transfer to another party
    function transferCandidate(
        uint256 _candidateId,
        uint256 _newPartyId
    ) external OnlyCommission {
        require(_candidateId < candidateCount, "icid");
        require(_newPartyId < partyCount, "ipid");

        // Check if the candidate exists
        Candidate storage candidate = candidates[_candidateId];
        require(candidate.voterId != 0, "nc");

        // Change the partyId to the new party
        candidate.partyId = _newPartyId;
    }

    // Function for a candidate to revoke their candidature
    function revokeCandidature(uint256 _candidateId) external OnlyCommission {
        require(_candidateId < candidateCount, "icid");

        // Check if the candidate exists
        Candidate storage candidate = candidates[_candidateId];
        require(candidate.voterId != 0, "nc");

        // Remove the candidate by setting the voterId to 0
        candidate.voterId = 0;
    }

    function getVoters() external view returns (Voter[] memory) {
        Voter[] memory voterList = new Voter[](voterCount);
        if (msg.sender != electionCommission) {
            return voterList;
        }
        for (uint256 i = 0; i < voterCount; i++) {
            voterList[i] = voters[registeredVoters[i]];
        }

        return voterList;
    }

    function getVoterDetails(
        address _voterAddress
    ) external view returns (Voter memory, string memory, string memory) {
        Voter storage voterInfo = voters[_voterAddress];
        string memory stateName = states[voterInfo.stateId].name;
        string memory constituencyName = constituencies[voterInfo.constituency]
            .name;
        return (voterInfo, stateName, constituencyName);
    }

    function getNonCandidates() external view returns (Voter[] memory) {
        uint256 nonCandidateCount = voterCount - candidateCount;
        Voter[] memory nonCandidateList = new Voter[](nonCandidateCount);

        uint256 nonCandidateIndex = 0;
        for (uint256 i = 0; i < voterCount; i++) {
            // Check if the voter is not a candidate
            bool isCandidate = false;
            for (uint256 j = 0; j < candidateCount; j++) {
                if (candidates[j].voterId - 1 == i) {
                    isCandidate = true;
                    break;
                }
            }

            if (!isCandidate) {
                nonCandidateList[nonCandidateIndex] = voters[
                    registeredVoters[i]
                ];
                nonCandidateIndex++;
            }
        }

        return nonCandidateList;
    }

    function getStates() external view returns (State[] memory) {
        State[] memory stateList = new State[](stateCount);

        for (uint256 i = 0; i < stateCount; i++) {
            stateList[i] = states[i];
        }

        return stateList;
    }

    function getConstituencies(
        uint256 _stateId
    ) external view returns (Constituency[] memory) {
        require(_stateId < stateCount, "isid");

        uint256 constituencyLength = states[_stateId]
            .registeredConstituencies
            .length;
        Constituency[] memory constituencyList = new Constituency[](
            constituencyLength
        );

        for (uint256 i = 0; i < constituencyLength; i++) {
            uint256 constituencyId = states[_stateId].registeredConstituencies[
                i
            ];
            constituencyList[i] = constituencies[constituencyId];
        }

        return constituencyList;
    }

    function getParties() external view returns (Party[] memory) {
        Party[] memory partyList = new Party[](partyCount);

        for (uint256 i = 0; i < partyCount; i++) {
            partyList[i] = parties[i];
        }

        return partyList;
    }

    function getCandidates() external view returns (Candidate[] memory) {
        Candidate[] memory candidateList = new Candidate[](candidateCount);

        for (uint256 i = 0; i < candidateCount; i++) {
            candidateList[i] = candidates[i];
        }

        return candidateList;
    }

    function getPartyDetails(
        uint256 _partyId
    ) external view returns (Party memory, Candidate[] memory) {
        require(_partyId < partyCount, "ipid");

        Candidate[] memory partyCandidates = new Candidate[](candidateCount);
        uint256 candidateIndex = 0;

        for (uint256 i = 0; i < candidateCount; i++) {
            if (candidates[i].partyId == _partyId) {
                uint256 voterId = candidates[i].voterId;
                partyCandidates[candidateIndex] = candidates[i];

                // Fetch the candidate's details from the voters mapping
                Voter memory candidateInfo = voters[
                    registeredVoters[voterId - 1]
                ];
                partyCandidates[candidateIndex].voterId = voterId;
                partyCandidates[candidateIndex].fullName = candidateInfo
                    .fullName;
                partyCandidates[candidateIndex].faceImageIpfsUrl = candidateInfo
                    .faceImageIpfsUrl;
                // partyCandidates[candidateIndex].stateId = candidateInfo.stateId;
                // partyCandidates[candidateIndex].constituencyId = candidateInfo.constituency;

                // // Fetch state and constituency names using their IDs
                // partyCandidates[candidateIndex].stateName = states[candidateInfo.stateId].name;
                // partyCandidates[candidateIndex].constituencyName = constituencies[candidateInfo.constituency].name;

                candidateIndex++;
            }
        }

        assembly {
            mstore(partyCandidates, candidateIndex)
        }

        return (parties[_partyId], partyCandidates);
    }

    struct ElectionData {
        uint256 id;
        bool isNationalLevel;
        uint256 stateId; // 0 for national-level elections
        bool isActive;
        uint256 startDate;
        uint256 endDate;
        mapping(uint256 => mapping(uint256 => uint256)) assignedCandidates;
        mapping(address => bool) voters;
    }

    mapping(uint256 => ElectionData) public elections;
    uint256 public electionCount;

    modifier onlyDuringElection(uint256 _electionId) {
        require(elections[_electionId].isActive, "einac");
        _;
    }

    function createElection(
        bool _isNationalLevelElection,
        uint256 _stateId,
        uint256 _startDate,
        uint256 _endDate
    ) external {
        uint256 electionId = electionCount++;
        elections[electionId].isNationalLevel = _isNationalLevelElection;
        elections[electionId].stateId = _stateId;
        elections[electionId].startDate = _startDate;
        elections[electionId].endDate = _endDate;
        elections[electionId].isActive = false;
    }

    function toggleIsElectionActive(uint256 _electionId) external {
        require(_electionId < electionCount, "ieid");
        elections[_electionId].isActive = !elections[_electionId].isActive;
    }

    function assignCandidateToConstituency(
        uint256 _electionId,
        uint256 _stateId,
        uint256 _constituencyId,
        uint256 _candidateId
    ) external {
        require(_electionId < electionCount, "ieid");
        require(_stateId < stateCount, "isid");
        require(
            _constituencyId < states[_stateId].registeredConstituencies.length,
            "icid"
        );
        require(_candidateId < candidateCount, "icid");
        elections[_electionId].assignedCandidates[_stateId][
            _constituencyId
        ] = _candidateId;
    }
}
